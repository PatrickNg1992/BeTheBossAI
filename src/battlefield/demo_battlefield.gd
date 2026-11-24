extends Node3D

## Demo battlefield root. Surfaces battle_finished so the Multiplayer Scene
## manager can swap everyone back to the Waiting Room when the battle ends.
## (Battle content and win/lose rules are the battle side's concern — this
## demo ends when the Boss Monster dies.)

signal battle_finished()
signal sync_applied(category: String, payload: Dictionary)

const PUCK_PUCK_PLACEHOLDER_SECONDS := 5.0
const ACTION_PLACEHOLDER_SECONDS := 5.0
const DEMO_INITIAL_ENERGY := 15.0
const FAST_PLAY_SPEEDS: Array[float] = [1.0, 1.5, 2.0, 2.5]
const FAST_PLAY_LABELS: Array[String] = ["x1", "x1.5", "x2", "x2.5"]
const WOOD_PANEL_TEX: Texture2D = preload("res://src/resource/battlefield/wood_panel.png")
const SWORD_ICON_TEX: Texture2D = preload("res://src/resource/battlefield/sword.png")
const DOUBLE_ARROW_ICON_TEX: Texture2D = preload("res://src/resource/battlefield/double_arrow.png")

const ROLE_A := "a"
const ROLE_B := "b"
const ROLE_SPECTATOR := "spectator"

@onready var _player: Node3D = $Player
@onready var timing_manager: TimingManager = %TimingManager
@onready var puck_velocity_manager: PuckVelocityManager = %PuckVelocityManager
@onready var cue_shot_manager: CueShotManager = %CueShotManager
@onready var unit_information_manager: UnitInformationManager = get_node_or_null("%UnitInformationManager") as UnitInformationManager
var unit_skill_manager: UnitSkillManager = null
var time_board_model: TimeBoardModel = null
@onready var time_board: TimeBoard = %TimeBoard
@onready var play_button: Button = %PlayButton
@onready var fast_play_button: Button = %FastPlayButton
@onready var pause_button: Button = %PauseButton
@onready var action_button: Button = %ActionButton
@onready var puck_puck_banner: TextureRect = %PuckPuckBanner
@onready var banner_label: Label = %BannerLabel

## Network & Host-authoritative session configuration.
## Defaults to a local LoopbackTransport (Single-Player: Host = 1, Player A = 1, Player B = 0)
## unless configured beforehand by SinglePlayerLoader or MultiplayerManager.
var transport: MpTransport = null
var is_host: bool = true
var local_peer_id: int = 1
var player_a_peer_id: int = 1
var player_b_peer_id: int = 0
var spectator_peer_ids: Array[int] = []
var active_player: String = ""
var last_shot_player: String = "a"
var pvp_winner_seat: String = ""
var _pvp_win_elapsed: float = 0.0
var _pvp_win_label: Label = null
var _pvp_win_countdown_label: Label = null
var _paused_center_label: Label = null
var _play_button_alert_count: int = 0
var _play_alert_tween: Tween = null
var stage_index: int = 0
var wave_index: int = 0
var ready_players: Array[String] = []

## Observable synced state and counters on this Peer's Battlefield instance.
var synced_state: Dictionary = {
	"timing": {},
	"time_board": {},
	"boss_stats": {},
	"units": {},
	"puck_positions": {},
	"cards": {},
	"aiming": {},
	"effect_trigger": {},
}
var sync_receive_counts: Dictionary = {
	"timing": 0,
	"time_board": 0,
	"boss_stats": 0,
	"units": 0,
	"puck_positions": 0,
	"cards": 0,
	"aiming": 0,
	"effect_trigger": 0,
}
var host_received_actions: Array[Dictionary] = []

var _session_configured: bool = false
var _puck_puck_elapsed: float = 0.0
var _action_elapsed: float = 0.0
var _fast_play_index: int = 0
var _banner_tween: Tween = null
var _play_style_ready: StyleBoxFlat = null
var _play_style_hover: StyleBoxFlat = null
var _play_style_pressed: StyleBoxFlat = null
var _play_style_cancel: StyleBoxFlat = null
var _play_style_cancel_hover: StyleBoxFlat = null
var _play_style_disabled: StyleBoxFlat = null


func configure_session(p_transport: MpTransport, p_is_host: bool, p_local_peer_id: int, seats: Dictionary) -> void:
	if transport != null and transport != p_transport:
		if transport.message_received.is_connected(_on_transport_message_received):
			transport.message_received.disconnect(_on_transport_message_received)
	transport = p_transport
	is_host = p_is_host
	local_peer_id = p_local_peer_id
	player_a_peer_id = int(seats.get("player_a", 1 if p_is_host else 0))
	player_b_peer_id = int(seats.get("player_b", 0))
	spectator_peer_ids.clear()
	for s_id in seats.get("spectators", []):
		spectator_peer_ids.append(int(s_id))
	_session_configured = true
	if transport != null and not transport.message_received.is_connected(_on_transport_message_received):
		transport.message_received.connect(_on_transport_message_received)
	_apply_role_and_authority_mode()


func get_local_role() -> String:
	return get_peer_role(local_peer_id)


func get_peer_role(peer_id: int) -> String:
	if peer_id != 0 and peer_id == player_a_peer_id:
		return ROLE_A
	if peer_id != 0 and peer_id == player_b_peer_id:
		return ROLE_B
	return ROLE_SPECTATOR


func has_player_b() -> bool:
	return player_b_peer_id != 0


func set_player_energy(seat: String, amount: float) -> void:
	if timing_manager != null:
		timing_manager.set_player_energy(seat, amount)


func get_player_energy(seat: String) -> float:
	if timing_manager != null:
		return timing_manager.get_player_energy(seat)
	return 0.0


func _ready() -> void:
	if not _session_configured:
		configure_session(LoopbackTransport.new(), true, LoopbackTransport.HOST_ID, {
			"player_a": LoopbackTransport.HOST_ID,
			"player_b": 0,
			"spectators": [],
		})
	if _player != null and _player.has_signal("died"):
		_player.died.connect(func() -> void:
			if is_host:
				battle_finished.emit()
		)

	_apply_role_and_authority_mode()
	_setup_demo_unit_information()
	if time_board_model == null:
		time_board_model = TimeBoardModel.new()
	time_board_model.bind(timing_manager, unit_information_manager, unit_skill_manager, has_player_b())
	timing_manager.set_energy(DEMO_INITIAL_ENERGY)
	timing_manager.set_energy_b(DEMO_INITIAL_ENERGY if has_player_b() else 0.0)

	timing_manager.timing_changed.connect(_on_timing_changed)
	timing_manager.charge_slot_completed.connect(_on_charge_slot_completed)
	timing_manager.energy_changed.connect(_on_energy_changed)
	timing_manager.pause_changed.connect(_on_pause_changed)
	timing_manager.fast_play_changed.connect(_on_fast_play_changed)
	if puck_velocity_manager != null and not puck_velocity_manager.all_pucks_at_rest.is_connected(_on_all_pucks_at_rest):
		puck_velocity_manager.all_pucks_at_rest.connect(_on_all_pucks_at_rest)

	play_button.pressed.connect(_on_play_button_pressed)
	fast_play_button.pressed.connect(_on_fast_play_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	action_button.pressed.connect(_on_action_button_pressed)
	Loc.language_changed.connect(_update_ui_labels)

	time_board.set_perspective_role(get_local_role())
	time_board.render_state(time_board_model.get_state())
	_bind_unit_info_sync_signals()
	if is_host:
		sync_time_board({}, MpTransport.RELIABLE)
		sync_boss_stats()
		sync_units()
	_setup_control_styles()
	_update_ui_labels()
	_refresh_controls()


func _apply_role_and_authority_mode() -> void:
	var is_single_player := is_host and player_b_peer_id == 0
	if timing_manager != null:
		timing_manager.set_single_player_mode(is_single_player)
		timing_manager.set_process(is_host)
		if has_player_b() and timing_manager.get_energy_b() <= 0.0001 and synced_state["time_board"].is_empty():
			timing_manager._energy_b = DEMO_INITIAL_ENERGY
	if puck_velocity_manager != null:
		puck_velocity_manager.set_process(is_host)
	if time_board_model != null:
		time_board_model.set_has_player_b(has_player_b())
	if time_board != null:
		time_board.set_perspective_role(get_local_role())
	var canvas_node := get_node_or_null("Canvas")
	if canvas_node != null and canvas_node.has_method("set_local_role"):
		canvas_node.call("set_local_role", get_local_role())
	for child in get_children():
		if child is BaseEnemy:
			child.set_physics_process(is_host)
			child.set_process(is_host)
		elif child is BasePuck and not is_host:
			child.set_physics_process(false)
			child.set_process(false)
	_refresh_controls()


func _process(delta: float) -> void:
	if not pvp_winner_seat.is_empty():
		_pvp_win_elapsed += delta
		var rem_sec := maxi(1, int(ceil(5.0 - _pvp_win_elapsed)))
		_update_pvp_win_countdown_label(rem_sec)
		if is_host and _pvp_win_elapsed >= 5.0 - 0.0001:
			_pvp_win_elapsed = 0.0
			battle_finished.emit()
		return
	if not is_host:
		return
	if timing_manager == null or timing_manager.is_paused():
		return
	var current := timing_manager.get_current_timing()
	if current == TimingManager.TIMING_PUCK_PUCK:
		_puck_puck_elapsed += delta * timing_manager.get_effective_time_scale()
		if _puck_puck_elapsed >= PUCK_PUCK_PLACEHOLDER_SECONDS - 0.00001:
			if puck_velocity_manager == null or puck_velocity_manager.are_all_pucks_at_rest():
				_puck_puck_elapsed = 0.0
				timing_manager.notify_all_pucks_at_rest()
				sync_timing()
	elif current == TimingManager.TIMING_ACTION:
		if is_host:
			sync_puck_positions({}, MpTransport.UNRELIABLE_ORDERED)
		_action_elapsed += delta * timing_manager.get_effective_time_scale()
		if _action_elapsed >= ACTION_PLACEHOLDER_SECONDS - 0.00001:
			_action_elapsed = 0.0
			timing_manager.notify_actions_finished()
			sync_puck_positions({}, MpTransport.RELIABLE)
			sync_timing()


func _unhandled_input(event: InputEvent) -> void:
	if timing_manager == null or timing_manager.is_paused():
		return
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if (key_event.keycode == KEY_SPACE or key_event.physical_keycode == KEY_SPACE) \
			and timing_manager.get_current_timing() == TimingManager.TIMING_PLAY:
		action_cue_shot(Vector3.ZERO, 0.0)


func _on_play_button_pressed() -> void:
	var current := timing_manager.get_current_timing()
	if current == TimingManager.TIMING_CHARGING:
		action_request_play()
	elif current == TimingManager.TIMING_PLAY:
		action_cancel_play()


# ----- Player Action Commands (Client / Local Input -> Host Authority) -----

func action_start_wave() -> void:
	_send_action_to_host("action_start_wave", {}, MpTransport.RELIABLE)


func action_request_play() -> void:
	_send_action_to_host("action_request_play", {}, MpTransport.RELIABLE)


func action_aim_update(aim_payload: Dictionary, transfer_mode: int = MpTransport.UNRELIABLE_ORDERED) -> void:
	_send_action_to_host("action_aim_update", aim_payload, transfer_mode)


func action_cue_shot(shot_direction: Vector3 = Vector3.ZERO, energy_cost: float = 0.0) -> void:
	_send_action_to_host("action_cue_shot", {
		"shot_direction": shot_direction,
		"energy_cost": energy_cost,
	}, MpTransport.RELIABLE)


func action_play_card(hand_index: int, target_pos: Vector3 = Vector3.ZERO, target_puck_id: int = -1) -> void:
	_send_action_to_host("action_play_card", {
		"hand_index": hand_index,
		"target_pos": target_pos,
		"target_puck_id": target_puck_id,
	}, MpTransport.RELIABLE)


func action_cancel_play() -> void:
	_send_action_to_host("action_cancel_play", {}, MpTransport.RELIABLE)


func action_toggle_pause() -> void:
	_send_action_to_host("action_toggle_pause", {}, MpTransport.RELIABLE)


func _send_action_to_host(action_name: String, payload: Dictionary, transfer_mode: int) -> void:
	var msg := {
		"type": "bf_action",
		"action": action_name,
		"payload": payload.duplicate(true),
	}
	if transport is LoopbackTransport:
		transport.send_to_host(msg, transfer_mode)
	elif is_host:
		if transport != null:
			transport.send_to_host(msg, transfer_mode)
		_handle_host_action(local_peer_id, action_name, payload.duplicate(true))
	elif transport != null:
		transport.send_to_host(msg, transfer_mode)


# ----- Host Authority Action Resolution -----

func _handle_host_action(sender_peer_id: int, action_name: String, payload: Dictionary) -> void:
	if not is_host or timing_manager == null:
		return
	var sender_role := get_peer_role(sender_peer_id)
	host_received_actions.append({
		"sender_peer_id": sender_peer_id,
		"sender_role": sender_role,
		"action": action_name,
		"payload": payload.duplicate(true),
	})
	# Spectators can never send gameplay actions.
	if sender_role != ROLE_A and sender_role != ROLE_B:
		return

	match action_name:
		"action_start_wave":
			if timing_manager.get_current_timing() != TimingManager.TIMING_PREPARE:
				return
			if not ready_players.has(sender_role):
				ready_players.append(sender_role)
			var all_ready := ready_players.has(ROLE_A) and (not has_player_b() or ready_players.has(ROLE_B))
			if all_ready:
				ready_players.clear()
				timing_manager.start_charging()
				sync_timing()
				sync_time_board( {}, MpTransport.RELIABLE)
			else:
				sync_timing()
		"action_request_play":
			if timing_manager.get_current_timing() != TimingManager.TIMING_CHARGING:
				return
			if puck_velocity_manager != null and not puck_velocity_manager.are_all_pucks_at_rest():
				return
			var prev_active := active_player
			active_player = sender_role
			if timing_manager.request_player_play(sender_role):
				sync_timing()
				sync_time_board({}, MpTransport.RELIABLE)
			else:
				active_player = prev_active
		"action_cancel_play":
			if timing_manager.get_current_timing() != TimingManager.TIMING_PLAY:
				return
			if active_player != "" and active_player != sender_role:
				return
			if timing_manager.cancel_play():
				active_player = ""
				if has_player_b():
					timing_manager.reset_play_used()
				sync_aiming({"active": false}, MpTransport.RELIABLE)
				sync_timing()
				sync_time_board({}, MpTransport.RELIABLE)
		"action_aim_update":
			if timing_manager.get_current_timing() != TimingManager.TIMING_PLAY:
				return
			if active_player != "" and active_player != sender_role:
				return
			var aim_data := payload.duplicate(true)
			aim_data["player_seat"] = sender_role
			var mode := MpTransport.UNRELIABLE_ORDERED if aim_data.get("active", true) else MpTransport.RELIABLE
			sync_aiming(aim_data, mode)
		"action_cue_shot":
			if timing_manager.get_current_timing() != TimingManager.TIMING_PLAY:
				return
			if active_player != "" and active_player != sender_role:
				return
			var cost := float(payload.get("energy_cost", 0.0))
			var dir := payload.get("shot_direction", Vector3.ZERO) as Vector3
			var is_debug_zero_shot := is_equal_approx(cost, 0.0) and dir.is_zero_approx()
			if not is_debug_zero_shot:
				if cost < CueShotManager.MIN_SHOT_ENERGY - 0.0001 or cost > CueShotManager.MAX_SHOT_ENERGY + 0.0001:
					return
				if not is_equal_approx(cost, snappedf(cost, CueShotManager.ENERGY_STEP)):
					return
				if cost > get_player_energy(sender_role) + 0.0001:
					return
			_puck_puck_elapsed = 0.0
			if cost > 0.0:
				timing_manager.consume_player_energy(sender_role, cost)
			var boss := _get_boss_puck_for_seat(sender_role)
			if boss != null and cost > 0.0 and dir.length_squared() > 0.0001:
				var imp_per_e := cue_shot_manager.impulse_per_energy if cue_shot_manager != null else 7.2
				boss.apply_impulse(dir.normalized() * (imp_per_e * cost))
			if timing_manager.fire_cue_shot(0.0):
				last_shot_player = sender_role
				active_player = ""
				sync_aiming({"active": false}, MpTransport.RELIABLE)
				if cost <= 0.0:
					sync_time_board({}, MpTransport.RELIABLE)
				sync_timing()
				sync_puck_positions({}, MpTransport.UNRELIABLE_ORDERED)
		"action_play_card":
			if timing_manager.get_current_timing() != TimingManager.TIMING_PLAY:
				return
			if active_player != "" and active_player != sender_role:
				return
			sync_cards()
			sync_timing()
		"action_toggle_pause":
			timing_manager.set_paused(not timing_manager.is_paused())
			sync_timing()


# ----- Modular Host -> All Peers Sync Functions -----

func sync_timing(payload: Dictionary = {}) -> void:
	if not is_host:
		return
	var data := payload.duplicate(true)
	if not data.has("timing") and timing_manager != null:
		data["timing"] = timing_manager.get_current_timing()
	if not data.has("active_player"):
		data["active_player"] = active_player
	if not data.has("stage_index"):
		data["stage_index"] = stage_index
	if not data.has("wave_index"):
		data["wave_index"] = wave_index
	if not data.has("ready_players"):
		data["ready_players"] = ready_players.duplicate()
	if not data.has("can_enter_play") and timing_manager != null:
		data["can_enter_play"] = timing_manager.can_enter_play()
	if not data.has("can_enter_play_a") and timing_manager != null:
		data["can_enter_play_a"] = timing_manager.can_player_enter_play(ROLE_A)
	if not data.has("can_enter_play_b") and timing_manager != null:
		data["can_enter_play_b"] = timing_manager.can_player_enter_play(ROLE_B)
	if not data.has("paused") and timing_manager != null:
		data["paused"] = timing_manager.is_paused()
	_dispatch_sync("timing", data, MpTransport.RELIABLE)


func sync_time_board(payload: Dictionary = {}, transfer_mode: int = MpTransport.RELIABLE) -> void:
	if not is_host:
		return
	var data := payload.duplicate(true)
	if not data.has("turn_progress") and timing_manager != null:
		data["turn_progress"] = timing_manager.get_charge_progress()
	if not data.has("energy_a") and timing_manager != null:
		data["energy_a"] = timing_manager.get_energy()
	if not data.has("energy_b") and timing_manager != null:
		data["energy_b"] = timing_manager.get_energy_b()
	if not data.has("has_player_b"):
		data["has_player_b"] = has_player_b()
	if not data.has("action_tags"):
		data["action_tags"] = time_board_model.get_state().get("tags", {}) if time_board_model != null else []
	if not data.has("cycle_tags") and time_board_model != null:
		data["cycle_tags"] = time_board_model.get_state().get("cycle_tags", [])
	if not data.has("unit_tag_turns"):
		data["unit_tag_turns"] = {}
	_dispatch_sync("time_board", data, transfer_mode)


func sync_boss_stats(payload: Dictionary = {}) -> void:
	if not is_host:
		return
	var data := payload.duplicate(true)
	if not data.has("bosses") and unit_information_manager != null:
		data.merge(unit_information_manager.export_boss_stats_snapshot(), true)
	_dispatch_sync("boss_stats", data, MpTransport.RELIABLE)


func sync_units(payload: Dictionary = {}) -> void:
	if not is_host:
		return
	var data := payload.duplicate(true)
	if not data.has("units") and unit_information_manager != null:
		data.merge(unit_information_manager.export_units_snapshot(), true)
	_dispatch_sync("units", data, MpTransport.RELIABLE)


func sync_puck_positions(payload: Dictionary = {}, transfer_mode: int = MpTransport.UNRELIABLE_ORDERED) -> void:
	if not is_host:
		return
	var data := payload.duplicate(true)
	if not data.has("pucks"):
		var puck_list: Array[Dictionary] = []
		for child in get_children():
			if child is BasePuck and is_instance_valid(child):
				var p := child as BasePuck
				puck_list.append({
					"puck_id": str(p.name),
					"position": p.global_position,
					"velocity": p.velocity,
					"rotation": p.rotation,
					"is_falling_in_pocket": p.is_falling_in_pocket,
				})
		data["pucks"] = puck_list
	_dispatch_sync("puck_positions", data, transfer_mode)


func sync_cards(payload: Dictionary = {}) -> void:
	if not is_host:
		return
	var data := payload.duplicate(true)
	_dispatch_sync("cards", data, MpTransport.RELIABLE)


func sync_aiming(payload: Dictionary = {}, transfer_mode: int = MpTransport.UNRELIABLE_ORDERED) -> void:
	if not is_host:
		return
	var data := payload.duplicate(true)
	_dispatch_sync("aiming", data, transfer_mode)


func sync_effect_trigger(payload: Dictionary = {}) -> void:
	if not is_host:
		return
	var data := payload.duplicate(true)
	_dispatch_sync("effect_trigger", data, MpTransport.RELIABLE)


func sync_all() -> void:
	if not is_host:
		return
	sync_timing()
	sync_time_board({}, MpTransport.RELIABLE)
	sync_boss_stats()
	sync_units()
	sync_puck_positions({}, MpTransport.RELIABLE)
	sync_cards()
	sync_aiming({"active": false}, MpTransport.RELIABLE)


func _dispatch_sync(category: String, payload: Dictionary, transfer_mode: int) -> void:
	var msg := {
		"type": "bf_sync",
		"category": category,
		"payload": payload.duplicate(true),
	}
	if transport is LoopbackTransport:
		transport.broadcast(msg, transfer_mode)
	else:
		if transport != null:
			transport.broadcast(msg, transfer_mode)
		_apply_sync(category, payload.duplicate(true))


func _on_transport_message_received(sender_id: int, message: Dictionary) -> void:
	var msg_type: String = str(message.get("type", ""))
	if msg_type == "bf_action":
		if is_host:
			_handle_host_action(sender_id, str(message.get("action", "")), message.get("payload", {}))
	elif msg_type == "bf_sync":
		if not is_host or transport is LoopbackTransport:
			_apply_sync(str(message.get("category", "")), message.get("payload", {}))


func _apply_sync(category: String, payload: Dictionary) -> void:
	synced_state[category] = payload.duplicate(true)
	sync_receive_counts[category] = int(sync_receive_counts.get(category, 0)) + 1
	match category:
		"timing":
			active_player = str(payload.get("active_player", active_player))
			stage_index = int(payload.get("stage_index", stage_index))
			wave_index = int(payload.get("wave_index", wave_index))
			if payload.has("ready_players"):
				ready_players.clear()
				for rp in payload.get("ready_players", []):
					ready_players.append(str(rp))
			var target_timing := str(payload.get("timing", ""))
			if payload.has("paused") and timing_manager != null:
				timing_manager.set_paused(bool(payload["paused"]))
			if not is_host and timing_manager != null and not target_timing.is_empty():
				if payload.has("can_enter_play"):
					timing_manager._play_used_in_current_slot = not bool(payload["can_enter_play"])
				if payload.has("can_enter_play_a"):
					timing_manager._play_used_by_seat[ROLE_A] = not bool(payload["can_enter_play_a"])
				if payload.has("can_enter_play_b"):
					timing_manager._play_used_by_seat[ROLE_B] = not bool(payload["can_enter_play_b"])
				if timing_manager.get_current_timing() != target_timing:
					timing_manager._transition_to(target_timing)
				for child in get_children():
					if child is BaseEnemy:
						(child as BaseEnemy)._ai_active = false
						child.set_physics_process(false)
						child.set_process(false)
			_refresh_controls()
		"time_board":
			var energy_a := float(payload.get("energy_a", timing_manager.get_energy() if timing_manager != null else 0.0))
			var energy_b := float(payload.get("energy_b", timing_manager.get_energy_b() if timing_manager != null else 0.0))
			var progress := float(payload.get("turn_progress", timing_manager.get_charge_progress() if timing_manager != null else 0.0))
			var two_p := bool(payload.get("has_player_b", has_player_b()))
			if is_host and timing_manager != null:
				timing_manager._charge_progress = progress
				timing_manager._energy = clampf(snappedf(energy_a, 0.5), 0.0, TimingManager.MAX_ENERGY)
				timing_manager._energy_b = clampf(snappedf(energy_b, 0.5), 0.0, TimingManager.MAX_ENERGY)
			elif not is_host and timing_manager != null:
				timing_manager._charge_progress = progress
				timing_manager._energy = clampf(snappedf(energy_a, 0.5), 0.0, TimingManager.MAX_ENERGY)
				timing_manager._energy_b = clampf(snappedf(energy_b, 0.5), 0.0, TimingManager.MAX_ENERGY)
			if time_board != null:
				time_board.set_perspective_role(get_local_role())
				var tb_state := {
					"energy": energy_a,
					"energy_a": energy_a,
					"energy_b": energy_b,
					"has_player_b": two_p,
					"charge": progress,
					"action_tags": payload.get("action_tags", []),
				}
				if payload.has("cycle_tags"):
					tb_state["cycle_tags"] = payload["cycle_tags"]
				time_board.apply_state(tb_state)
		"aiming":
			if cue_shot_manager != null and cue_shot_manager.has_method("apply_synced_aiming"):
				cue_shot_manager.apply_synced_aiming(payload)
		"boss_stats":
			if not is_host and unit_information_manager != null:
				unit_information_manager.apply_boss_stats_snapshot(payload)
		"units":
			if not is_host and unit_information_manager != null:
				unit_information_manager.apply_units_snapshot(payload)
		"effect_trigger":
			_apply_synced_effect_trigger(payload)
		"puck_positions":
			if not is_host:
				for item in payload.get("pucks", []):
					if item is Dictionary:
						var pid := str(item.get("puck_id", ""))
						var node := get_node_or_null(pid) as BasePuck
						if node != null and is_instance_valid(node):
							if item.has("position"):
								node.global_position = item["position"] as Vector3
							if item.has("velocity"):
								node.velocity = item["velocity"] as Vector3
							if item.has("rotation"):
								node.rotation = item["rotation"] as Vector3
							if item.has("is_falling_in_pocket"):
								node.is_falling_in_pocket = bool(item["is_falling_in_pocket"])
	sync_applied.emit(category, payload.duplicate(true))


func _get_boss_puck_for_seat(seat: String) -> BasePuck:
	if seat == ROLE_B:
		var pb := get_node_or_null("PlayerB") as BasePuck
		if pb != null:
			return pb
	return _player as BasePuck


func _setup_demo_unit_information() -> void:
	if unit_information_manager == null:
		unit_information_manager = get_node_or_null("UnitInformationManager") as UnitInformationManager
	if unit_information_manager == null:
		return
	if unit_skill_manager == null:
		unit_skill_manager = get_node_or_null("UnitSkillManager") as UnitSkillManager
		if unit_skill_manager == null:
			unit_skill_manager = UnitSkillManager.new()
			unit_skill_manager.name = "UnitSkillManager"
			add_child(unit_skill_manager)
	unit_skill_manager.bind_unit_information_manager(unit_information_manager)
	unit_information_manager.clear_all()

	if has_player_b():
		_setup_multiplayer_pvp_battlefield()
		return

	unit_information_manager.configure_mode(UnitInformationManager.MODE_SINGLE_PLAYER)

	# 1. Register Player A Boss Monster
	if _player is BaseBossMonster:
		var boss_a := _player as BaseBossMonster
		unit_information_manager.register_boss("boss_a", "a", {
			"max_hp": 1000,
			"current_hp": 1000,
			"bars_remaining": 15,
			"max_bars": 15,
			"power": 400,
			"mass": boss_a.mass,
			"radius": boss_a.radius,
			"puck": boss_a,
		})

	# 2. Register Adventurer Team 1 (6 members: Enemy1..Enemy6, with ?5 and ?6 assigned random distinct classes)
	var all_classes: Array[int] = [
		EnemyAdventurer.AdventurerClass.BRAWLER,
		EnemyAdventurer.AdventurerClass.GUARD,
		EnemyAdventurer.AdventurerClass.ACOLYTE,
		EnemyAdventurer.AdventurerClass.SCOUT,
	]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var dup_class_5: int = all_classes[rng.randi_range(0, all_classes.size() - 1)]
	var remaining_classes: Array[int] = []
	for c in all_classes:
		if c != dup_class_5:
			remaining_classes.append(c)
	var dup_class_6: int = remaining_classes[rng.randi_range(0, remaining_classes.size() - 1)]

	var e5 := get_node_or_null("Enemy5") as EnemyAdventurer
	var e6 := get_node_or_null("Enemy6") as EnemyAdventurer
	if e5 != null:
		e5.adventurer_class = dup_class_5 as EnemyAdventurer.AdventurerClass
	if e6 != null:
		e6.adventurer_class = dup_class_6 as EnemyAdventurer.AdventurerClass

	var team1_members: Array = []
	for idx in range(1, 7):
		var en := get_node_or_null("Enemy%d" % idx) as EnemyAdventurer
		if en != null:
			team1_members.append({
				"unit_id": "enemy_%d" % idx,
				"adventurer_class": int(en.adventurer_class),
				"mass": en.mass,
				"radius": en.radius,
				"puck": en,
			})
	if not team1_members.is_empty():
		unit_information_manager.register_adventurer_team(1, team1_members)

	# 3. Register Adventurer Team 2 (4 members: Enemy7..Enemy10 -> Knight, Warrior, Ranger, Mage)
	var team2_members: Array = []
	for idx in range(7, 11):
		var en := get_node_or_null("Enemy%d" % idx) as EnemyAdventurer
		if en != null:
			team2_members.append({
				"unit_id": "enemy_%d" % idx,
				"adventurer_class": int(en.adventurer_class),
				"mass": en.mass,
				"radius": en.radius,
				"puck": en,
			})
	if not team2_members.is_empty():
		unit_information_manager.register_adventurer_team(2, team2_members)

	var canvas_node := get_node_or_null("Canvas")
	if canvas_node != null and canvas_node.has_method("set_local_role"):
		canvas_node.call("set_local_role", get_local_role())


func _setup_multiplayer_pvp_battlefield() -> void:
	unit_information_manager.configure_mode(UnitInformationManager.MODE_TWO_PLAYER_VS)

	# 1. Remove the single-player demo Enemy1..Enemy10 pucks
	for idx in range(1, 11):
		var old_en := get_node_or_null("Enemy%d" % idx)
		if old_en != null:
			remove_child(old_en)
			old_en.free()

	# 2. Move Player A's Boss Monster puck to original Enemy2 position (-6, 1.8, 3)
	if _player is BaseBossMonster:
		var boss_a := _player as BaseBossMonster
		boss_a.global_position = Vector3(-6.0, 1.8, 3.0)
		boss_a.velocity = Vector3.ZERO
		unit_information_manager.register_boss("boss_a", "a", {
			"name_key": "uib_boss_dragon",
			"avatar_path": UnitInformationManager.AVATAR_BOSS_DRAGON,
			"max_hp": 1000,
			"current_hp": 1000,
			"bars_remaining": 15,
			"max_bars": 15,
			"power": 400,
			"mass": boss_a.mass,
			"radius": boss_a.radius,
			"puck": boss_a,
		})

	# 3. Create Player B's Skeleton Boss Monster puck at original Enemy3 position (6, 1.8, -3)
	var player_b := get_node_or_null("PlayerB") as BaseBossMonster
	if player_b == null:
		player_b = _spawn_boss_puck_node("PlayerB", Vector3(6.0, 1.8, -3.0))
	else:
		player_b.global_position = Vector3(6.0, 1.8, -3.0)
		player_b.velocity = Vector3.ZERO
	unit_information_manager.register_boss("boss_b", "b", {
		"name_key": "uib_boss_skeleton",
		"avatar_path": UnitInformationManager.AVATAR_BOSS_SKELETON,
		"max_hp": 1000,
		"current_hp": 1000,
		"bars_remaining": 15,
		"max_bars": 15,
		"power": 400,
		"mass": player_b.mass,
		"radius": player_b.radius,
		"puck": player_b,
	})

	# 4. Spawn 6-Adventurer snooker triangle for Player A around original Enemy4 (-6, -3) facing +X,
	#    and for Player B around original Enemy1 (6, 3) facing -X.
	#    Front line (apex): Guard (G/g, Guard)
	#    Second line: Brawler (B/b, Brawler) and Scout (S/s, Scout on the side nearer its own Boss Monster)
	#    Third line: Free (F/f, Brawler on outer side), Acolyte (A/a, Acolyte in middle), and Extra (E/e, Scout on side nearer Boss)
	var team_a_members := _spawn_pvp_adventurer_triangle("a", 1, Vector3(-6.0, 0.0, -3.0), 1.0, 1.0)
	unit_information_manager.register_adventurer_team(1, team_a_members)

	var team_b_members := _spawn_pvp_adventurer_triangle("b", 2, Vector3(6.0, 0.0, 3.0), -1.0, -1.0)
	unit_information_manager.register_adventurer_team(2, team_b_members)

	var canvas_node := get_node_or_null("Canvas")
	if canvas_node != null and canvas_node.has_method("set_local_role"):
		canvas_node.call("set_local_role", get_local_role())


func _spawn_boss_puck_node(node_name: String, world_pos: Vector3) -> DragonPlayer:
	var bp := DragonPlayer.new()
	bp.name = node_name
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = 0.8
	cyl_shape.height = 0.6
	col.shape = cyl_shape
	bp.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "PuckMesh"
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = 0.8
	cyl_mesh.bottom_radius = 0.8
	cyl_mesh.height = 0.6
	mesh_inst.mesh = cyl_mesh
	bp.add_child(mesh_inst)

	add_child(bp)
	bp.global_position = world_pos
	return bp


func _spawn_pvp_adventurer_triangle(
	owner_seat: String,
	team_index: int,
	center_xz: Vector3,
	facing_x_sign: float,
	boss_side_z_sign: float
) -> Array:
	var row_dx := 1.25
	var col_dz := 0.72
	# Specs for slots 1..6:
	# 1 (G/g): Guard at Front line (center_x + facing_x_sign * row_dx, center_z)
	# 2 (B/b): Brawler at Second line, outer Z (center_x, center_z - boss_side_z_sign * col_dz)
	# 3 (S/s): Scout at Second line, inner Z nearer Boss (center_x, center_z + boss_side_z_sign * col_dz)
	# 4 (A/a): Acolyte at Third line, middle Z (center_x - facing_x_sign * row_dx, center_z)
	# 5 (F/f): Brawler at Third line, outer Z (center_x - facing_x_sign * row_dx, center_z - boss_side_z_sign * col_dz * 2.0)
	# 6 (E/e): Scout at Third line, inner Z nearer Boss (center_x - facing_x_sign * row_dx, center_z + boss_side_z_sign * col_dz * 2.0)
	var specs := [
		{"slot": 1, "class": EnemyAdventurer.AdventurerClass.GUARD, "pos": Vector3(center_xz.x + facing_x_sign * row_dx, 1.70, center_xz.z)},
		{"slot": 2, "class": EnemyAdventurer.AdventurerClass.BRAWLER, "pos": Vector3(center_xz.x, 1.675, center_xz.z - boss_side_z_sign * col_dz)},
		{"slot": 3, "class": EnemyAdventurer.AdventurerClass.SCOUT, "pos": Vector3(center_xz.x, 1.675, center_xz.z + boss_side_z_sign * col_dz)},
		{"slot": 4, "class": EnemyAdventurer.AdventurerClass.ACOLYTE, "pos": Vector3(center_xz.x - facing_x_sign * row_dx, 1.675, center_xz.z)},
		{"slot": 5, "class": EnemyAdventurer.AdventurerClass.BRAWLER, "pos": Vector3(center_xz.x - facing_x_sign * row_dx, 1.675, center_xz.z - boss_side_z_sign * col_dz * 2.0)},
		{"slot": 6, "class": EnemyAdventurer.AdventurerClass.SCOUT, "pos": Vector3(center_xz.x - facing_x_sign * row_dx, 1.675, center_xz.z + boss_side_z_sign * col_dz * 2.0)},
	]

	var members: Array = []
	for sp in specs:
		var slot_num: int = int(sp["slot"])
		var adv_cls: int = int(sp["class"])
		var pos: Vector3 = sp["pos"] as Vector3
		var node_name := "PvP_%s_%d" % [owner_seat.to_upper(), slot_num]
		var puck := _spawn_adventurer_puck_node(node_name, adv_cls, pos)
		members.append({
			"unit_id": "pvp_%s_%d" % [owner_seat, slot_num],
			"owner_seat": owner_seat,
			"slot_override": slot_num,
			"adventurer_class": adv_cls,
			"mass": puck.mass,
			"radius": puck.radius,
			"puck": puck,
		})
	return members


func _spawn_adventurer_puck_node(node_name: String, adv_cls: int, world_pos: Vector3) -> EnemyAdventurer:
	var cfg: Dictionary = EnemyAdventurer.CLASS_CONFIG.get(adv_cls, EnemyAdventurer.CLASS_CONFIG[EnemyAdventurer.AdventurerClass.BRAWLER])
	var r: float = float(cfg.get("radius", 0.6))
	var h: float = 0.40 if adv_cls == EnemyAdventurer.AdventurerClass.GUARD else 0.35

	var en := EnemyAdventurer.new()
	en.name = node_name
	en.adventurer_class = adv_cls as EnemyAdventurer.AdventurerClass

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = r
	cyl_shape.height = h
	col.shape = cyl_shape
	en.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "MeshInstance3D"
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = r
	cyl_mesh.bottom_radius = r
	cyl_mesh.height = h
	mesh_inst.mesh = cyl_mesh
	en.add_child(mesh_inst)

	add_child(en)
	en.global_position = world_pos
	if not is_host:
		en.set_physics_process(false)
		en.set_process(false)
	return en


func _on_all_pucks_at_rest() -> void:
	if is_host:
		sync_puck_positions({}, MpTransport.RELIABLE)


func _on_fast_play_pressed() -> void:
	if not timing_manager.single_player_mode:
		return
	_fast_play_index = (_fast_play_index + 1) % FAST_PLAY_SPEEDS.size()
	var speed := FAST_PLAY_SPEEDS[_fast_play_index]
	timing_manager.fast_play_multiplier = speed
	timing_manager.set_fast_play(speed > 1.0)
	_refresh_controls()


func _on_pause_button_pressed() -> void:
	action_toggle_pause()


func _on_action_button_pressed() -> void:
	_action_elapsed = 0.0
	timing_manager.enter_action_time()


func _on_timing_changed(new_timing: String, _old_timing: String) -> void:
	if new_timing == TimingManager.TIMING_PUCK_PUCK:
		_puck_puck_elapsed = 0.0
		_flash_puck_puck_banner()
	elif new_timing == TimingManager.TIMING_PLAY:
		if has_player_b():
			var my_role := get_local_role()
			if not active_player.is_empty() and active_player != my_role:
				_flash_puck_puck_banner(Loc.t("pvp_opponent_takes_play"))
	elif new_timing == TimingManager.TIMING_CHARGING:
		if not _old_timing.is_empty() and _old_timing != TimingManager.TIMING_CHARGING:
			_alert_play_button()
	elif new_timing == TimingManager.TIMING_ACTION:
		_action_elapsed = 0.0
	elif new_timing == TimingManager.TIMING_SETTLE:
		if is_host:
			resolve_settle_and_check_pvp_winner()
	if is_host and (new_timing == TimingManager.TIMING_SETTLE or new_timing == TimingManager.TIMING_PREPARE):
		sync_puck_positions({}, MpTransport.RELIABLE)
	if is_host and new_timing == TimingManager.TIMING_CHARGING and _old_timing != TimingManager.TIMING_PLAY:
		timing_manager.reset_play_used()
		active_player = ""
	if time_board != null and timing_manager != null:
		var scale_f := maxf(timing_manager.get_effective_time_scale(), 1.0)
		time_board.turn_duration = timing_manager.turn_duration / scale_f
	_refresh_controls()
	if is_host:
		sync_timing()
		if new_timing == TimingManager.TIMING_CHARGING or new_timing == TimingManager.TIMING_ACTION or new_timing == TimingManager.TIMING_PREPARE:
			sync_time_board({}, MpTransport.RELIABLE)
			sync_units()


func _bind_unit_info_sync_signals() -> void:
	if unit_information_manager == null:
		return
	if not unit_information_manager.unit_damage_pushed.is_connected(_on_host_unit_damage_pushed):
		unit_information_manager.unit_damage_pushed.connect(_on_host_unit_damage_pushed)
	if not unit_information_manager.unit_collision_impulse_received.is_connected(_on_host_unit_collision_impulse):
		unit_information_manager.unit_collision_impulse_received.connect(_on_host_unit_collision_impulse)


func _on_host_unit_damage_pushed(u: UnitInformationDO, dmg_do: DamageDO) -> void:
	if not is_host or u == null or dmg_do == null:
		return
	sync_boss_stats()
	sync_units()
	sync_effect_trigger({
		"kind": "damage_pushed",
		"unit_id": u.unit_id,
		"grid_id": u.grid_id,
		"value": dmg_do.value,
	})


func _on_host_unit_collision_impulse(u: UnitInformationDO, impulse_mag: float) -> void:
	if not is_host or u == null:
		return
	sync_effect_trigger({
		"kind": "collision_impulse",
		"unit_id": u.unit_id,
		"grid_id": u.grid_id,
		"impulse": impulse_mag,
	})


func resolve_settle_and_check_pvp_winner() -> void:
	if not is_host or unit_information_manager == null:
		return
	var res: Dictionary = time_board_model.on_settle_time_resolved() if time_board_model != null else unit_information_manager.settle_all_damage()
	var settled_map: Dictionary = res.get("settled_damage", {})
	sync_time_board({}, MpTransport.RELIABLE)
	sync_boss_stats()
	sync_units()
	if not settled_map.is_empty():
		sync_effect_trigger({
			"kind": "damage_settled",
			"settled_damage": settled_map,
			"frenzy_spread": bool(res.get("frenzy_spread_triggered", false)),
		})
	if has_player_b() and pvp_winner_seat.is_empty():
		_check_multiplayer_pvp_winner()


func _check_multiplayer_pvp_winner() -> void:
	if not is_host or not has_player_b() or unit_information_manager == null:
		return
	var alive_a := 0
	var alive_b := 0
	var total_a := 0
	var total_b := 0
	for u in unit_information_manager.get_all_units():
		if u.unit_kind != "enemy_adventurer":
			continue
		if u.owner_seat == "a":
			total_a += 1
			if not u.is_dead:
				alive_a += 1
		elif u.owner_seat == "b":
			total_b += 1
			if not u.is_dead:
				alive_b += 1
	if total_a == 0 or total_b == 0:
		return
	var winner := ""
	if alive_a == 0 and alive_b == 0:
		winner = last_shot_player if (last_shot_player == "a" or last_shot_player == "b") else "a"
	elif alive_b == 0:
		winner = "a"
	elif alive_a == 0:
		winner = "b"
	if not winner.is_empty():
		pvp_winner_seat = winner
		_pvp_win_elapsed = 0.0
		_show_pvp_win_banner(winner)
		sync_effect_trigger({
			"kind": "pvp_winner",
			"winner_seat": winner,
		})


func _apply_synced_effect_trigger(payload: Dictionary) -> void:
	var kind := str(payload.get("kind", ""))
	var canvas_node := get_node_or_null("Canvas")
	var board: UnitInformationBoard = canvas_node.get("unit_information_board") if canvas_node != null and "unit_information_board" in canvas_node else null
	match kind:
		"damage_pushed":
			if not is_host and board != null:
				var gid := str(payload.get("grid_id", ""))
				var cell := board.get_unit_display(gid)
				if cell != null:
					cell.trigger_damage_badge_shake(float(payload.get("value", 0.0)))
		"collision_impulse":
			if not is_host and board != null:
				var gid := str(payload.get("grid_id", ""))
				var cell := board.get_unit_display(gid)
				if cell != null:
					cell.trigger_collision_impulse_shake(float(payload.get("impulse", 0.0)))
		"damage_settled":
			if not is_host and board != null:
				var settled_map: Dictionary = payload.get("settled_damage", {})
				if bool(payload.get("frenzy_spread", false)):
					board._on_frenzy_power_spread_started(settled_map)
				board._on_damage_settled(settled_map)
		"pvp_winner":
			var w_seat := str(payload.get("winner_seat", ""))
			if not w_seat.is_empty():
				pvp_winner_seat = w_seat
				_pvp_win_elapsed = 0.0
				_show_pvp_win_banner(w_seat)


func _show_pvp_win_banner(winner_seat: String) -> void:
	var msg := Loc.t("pvp_player_b_win") if winner_seat == "b" else Loc.t("pvp_player_a_win")
	var canvas_node := get_node_or_null("Canvas")
	if _pvp_win_label == null or not is_instance_valid(_pvp_win_label):
		_pvp_win_label = Label.new()
		_pvp_win_label.name = "PvPWinBannerLabel"
		_pvp_win_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_pvp_win_label.offset_left = -280
		_pvp_win_label.offset_right = 280
		_pvp_win_label.offset_top = -65
		_pvp_win_label.offset_bottom = 5
		_pvp_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pvp_win_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_pvp_win_label.add_theme_font_size_override("font_size", 46)
		_pvp_win_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.28, 1.0))
		_pvp_win_label.add_theme_color_override("font_outline_color", Color(0.10, 0.04, 0.02, 0.98))
		_pvp_win_label.add_theme_constant_override("outline_size", 10)
		_pvp_win_label.z_index = 50
		if canvas_node != null:
			canvas_node.add_child(_pvp_win_label)
		else:
			add_child(_pvp_win_label)
	if _pvp_win_countdown_label == null or not is_instance_valid(_pvp_win_countdown_label):
		_pvp_win_countdown_label = Label.new()
		_pvp_win_countdown_label.name = "PvPWinCountdownLabel"
		_pvp_win_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_pvp_win_countdown_label.offset_left = -280
		_pvp_win_countdown_label.offset_right = 280
		_pvp_win_countdown_label.offset_top = 8
		_pvp_win_countdown_label.offset_bottom = 52
		_pvp_win_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pvp_win_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_pvp_win_countdown_label.add_theme_font_size_override("font_size", 24)
		_pvp_win_countdown_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.80, 1.0))
		_pvp_win_countdown_label.add_theme_color_override("font_outline_color", Color(0.08, 0.03, 0.02, 0.98))
		_pvp_win_countdown_label.add_theme_constant_override("outline_size", 6)
		_pvp_win_countdown_label.z_index = 50
		if canvas_node != null:
			canvas_node.add_child(_pvp_win_countdown_label)
		else:
			add_child(_pvp_win_countdown_label)
	_pvp_win_label.text = msg
	_pvp_win_label.visible = true
	_update_pvp_win_countdown_label(5)


func _update_pvp_win_countdown_label(seconds_left: int) -> void:
	if _pvp_win_countdown_label != null and is_instance_valid(_pvp_win_countdown_label):
		_pvp_win_countdown_label.text = Loc.t("pvp_return_in_sec", {"sec": maxi(1, seconds_left)})
		_pvp_win_countdown_label.visible = true


func get_win_banner_text() -> String:
	if _pvp_win_label != null and is_instance_valid(_pvp_win_label) and _pvp_win_label.visible:
		var sub := _pvp_win_countdown_label.text if (_pvp_win_countdown_label != null and is_instance_valid(_pvp_win_countdown_label) and _pvp_win_countdown_label.visible) else ""
		return (_pvp_win_label.text + "\n" + sub).strip_edges()
	return ""


func get_play_button_alert_count() -> int:
	return _play_button_alert_count


func _alert_play_button() -> void:
	_play_button_alert_count += 1
	if play_button == null or not is_inside_tree():
		return
	if _play_alert_tween != null and _play_alert_tween.is_running():
		_play_alert_tween.kill()
	play_button.pivot_offset = play_button.size * 0.5 if play_button.size.x > 4.0 else play_button.custom_minimum_size * 0.5
	play_button.scale = Vector2(1.16, 1.16)
	play_button.modulate = Color(1.3, 1.25, 0.85, 1.0)
	_play_alert_tween = create_tween()
	_play_alert_tween.tween_property(play_button, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_play_alert_tween.parallel().tween_property(play_button, "modulate", Color.WHITE, 0.45)


func _on_charge_slot_completed(_new_energy: float) -> void:
	_refresh_controls()
	if is_host:
		sync_timing()
		sync_time_board({}, MpTransport.RELIABLE)


func _on_energy_changed(new_energy: float, charge_progress: float) -> void:
	var prev_tb: Dictionary = synced_state.get("time_board", {})
	var prev_a := float(prev_tb.get("energy_a", new_energy))
	var prev_b := float(prev_tb.get("energy_b", timing_manager.get_energy_b() if timing_manager != null else 0.0))
	var cur_b := timing_manager.get_energy_b() if timing_manager != null else 0.0
	var energy_changed_discrete := not is_equal_approx(new_energy, prev_a) or not is_equal_approx(cur_b, prev_b)
	if is_host:
		var mode := MpTransport.RELIABLE if energy_changed_discrete else MpTransport.UNRELIABLE_ORDERED
		sync_time_board({}, mode)
	elif time_board != null:
		time_board.set_perspective_role(get_local_role())
		time_board.apply_state({
			"energy": new_energy,
			"energy_a": new_energy,
			"energy_b": cur_b,
			"has_player_b": has_player_b(),
			"charge": charge_progress,
		})


func _on_pause_changed(_paused: bool) -> void:
	_refresh_controls()


func _on_fast_play_changed(enabled: bool) -> void:
	if not enabled:
		_fast_play_index = 0
	elif _fast_play_index == 0:
		var idx := FAST_PLAY_SPEEDS.find(timing_manager.fast_play_multiplier)
		_fast_play_index = idx if idx > 0 else 2
	if time_board != null and timing_manager != null:
		var scale_f := maxf(timing_manager.get_effective_time_scale(), 1.0)
		time_board.turn_duration = timing_manager.turn_duration / scale_f
	_refresh_controls()


func _update_ui_labels() -> void:
	if action_button != null:
		action_button.text = Loc.t("timing_action")
	if banner_label != null:
		banner_label.text = Loc.t("timing_puck_puck_time")
	_refresh_controls()


func _refresh_controls() -> void:
	if timing_manager == null:
		return
	var current := timing_manager.get_current_timing()
	var paused := timing_manager.is_paused()
	var my_role := get_local_role()
	if play_button != null:
		if current == TimingManager.TIMING_PLAY:
			var is_my_play := (active_player == "" or active_player == my_role) and my_role != ROLE_SPECTATOR
			if is_my_play:
				play_button.text = Loc.t("timing_cancel")
				play_button.icon = null
				play_button.disabled = paused
				_apply_play_button_mode(true, paused)
			else:
				play_button.text = Loc.t("timing_waiting")
				play_button.icon = null
				play_button.disabled = true
				_apply_play_button_mode(false, true)
		elif current == TimingManager.TIMING_CHARGING:
			play_button.text = Loc.t("timing_play")
			play_button.icon = SWORD_ICON_TEX
			var can_my_seat_play := timing_manager.can_player_enter_play(my_role) if has_player_b() else timing_manager.can_enter_play()
			var is_disabled := paused or not can_my_seat_play or my_role == ROLE_SPECTATOR
			play_button.disabled = is_disabled
			_apply_play_button_mode(false, is_disabled)
		else:
			play_button.text = Loc.t("timing_play")
			play_button.icon = SWORD_ICON_TEX
			play_button.disabled = true
			_apply_play_button_mode(false, true)
	if fast_play_button != null:
		fast_play_button.visible = timing_manager.single_player_mode
		fast_play_button.icon = DOUBLE_ARROW_ICON_TEX
		fast_play_button.text = FAST_PLAY_LABELS[_fast_play_index]
	if pause_button != null:
		pause_button.text = Loc.t("timing_resume") if paused else Loc.t("timing_pause")
	_update_paused_center_label(paused)
	if action_button != null:
		action_button.text = Loc.t("timing_action")
		action_button.disabled = paused or current == TimingManager.TIMING_ACTION


func _update_paused_center_label(paused: bool) -> void:
	if not paused:
		if _paused_center_label != null and is_instance_valid(_paused_center_label):
			_paused_center_label.visible = false
		return
	var canvas_node := get_node_or_null("Canvas")
	if _paused_center_label == null or not is_instance_valid(_paused_center_label):
		_paused_center_label = Label.new()
		_paused_center_label.name = "PausedCenterLabel"
		_paused_center_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_paused_center_label.offset_left = -220
		_paused_center_label.offset_right = 220
		_paused_center_label.offset_top = -45
		_paused_center_label.offset_bottom = 45
		_paused_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_paused_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_paused_center_label.add_theme_font_size_override("font_size", 48)
		_paused_center_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.42, 1.0))
		_paused_center_label.add_theme_color_override("font_outline_color", Color(0.08, 0.03, 0.02, 0.98))
		_paused_center_label.add_theme_constant_override("outline_size", 10)
		_paused_center_label.z_index = 48
		_paused_center_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if canvas_node != null:
			canvas_node.add_child(_paused_center_label)
		else:
			add_child(_paused_center_label)
	_paused_center_label.text = Loc.t("timing_paused")
	_paused_center_label.visible = true


func is_paused_banner_visible() -> bool:
	return _paused_center_label != null and is_instance_valid(_paused_center_label) and _paused_center_label.visible


func _setup_control_styles() -> void:
	_play_style_ready = _make_button_box(
		Color(0.56, 0.14, 0.12, 0.96),
		Color(0.95, 0.74, 0.22, 1.0),
		2
	)
	_play_style_hover = _make_button_box(
		Color(0.68, 0.20, 0.16, 0.98),
		Color(1.0, 0.86, 0.36, 1.0),
		2
	)
	_play_style_pressed = _make_button_box(
		Color(0.42, 0.10, 0.09, 0.98),
		Color(0.85, 0.64, 0.18, 1.0),
		2
	)
	_play_style_cancel = _make_button_box(
		Color(0.24, 0.26, 0.32, 0.96),
		Color(0.78, 0.82, 0.90, 0.95),
		2
	)
	_play_style_cancel_hover = _make_button_box(
		Color(0.32, 0.35, 0.42, 0.98),
		Color(0.92, 0.95, 1.0, 1.0),
		2
	)
	_play_style_disabled = _make_button_box(
		Color(0.18, 0.16, 0.15, 0.72),
		Color(0.36, 0.32, 0.28, 0.65),
		2
	)

	var aux_normal := _make_button_box(
		Color(0.26, 0.18, 0.11, 0.90),
		Color(0.58, 0.42, 0.24, 0.90),
		1
	)
	var aux_hover := _make_button_box(
		Color(0.34, 0.24, 0.15, 0.95),
		Color(0.78, 0.58, 0.32, 0.95),
		1
	)
	for btn: Button in [fast_play_button, pause_button, action_button]:
		if btn == null:
			continue
		btn.add_theme_stylebox_override("normal", aux_normal)
		btn.add_theme_stylebox_override("hover", aux_hover)
		btn.add_theme_stylebox_override("pressed", aux_hover)
		btn.add_theme_stylebox_override("disabled", _play_style_disabled)
		btn.add_theme_color_override("font_color", Color(0.94, 0.88, 0.72, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.84, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.98, 0.80, 0.28, 1.0))
		btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.48, 0.75))


func _make_button_box(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(6)
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	box.content_margin_top = 6.0
	box.content_margin_bottom = 6.0
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 2)
	return box


func _apply_play_button_mode(is_cancel_mode: bool, is_disabled: bool) -> void:
	if play_button == null or _play_style_ready == null:
		return
	play_button.add_theme_stylebox_override("disabled", _play_style_disabled)
	play_button.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.48, 0.75))
	play_button.add_theme_color_override("icon_disabled_color", Color(0.55, 0.52, 0.48, 0.55))
	if is_cancel_mode:
		play_button.add_theme_stylebox_override("normal", _play_style_cancel)
		play_button.add_theme_stylebox_override("hover", _play_style_cancel_hover)
		play_button.add_theme_stylebox_override("pressed", _play_style_cancel)
		play_button.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1.0))
		play_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		play_button.add_theme_stylebox_override("normal", _play_style_ready)
		play_button.add_theme_stylebox_override("hover", _play_style_hover)
		play_button.add_theme_stylebox_override("pressed", _play_style_pressed)
		play_button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.76, 1.0))
		play_button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.88, 1.0))
		play_button.add_theme_color_override("icon_normal_color", Color(1.0, 0.92, 0.68, 1.0))
	play_button.modulate = Color(0.85, 0.85, 0.85, 0.9) if is_disabled else Color.WHITE


func _flash_puck_puck_banner(custom_text: String = "") -> void:
	if puck_puck_banner == null:
		return
	if _banner_tween != null and _banner_tween.is_running():
		_banner_tween.kill()
	if banner_label != null:
		banner_label.text = custom_text if not custom_text.is_empty() else Loc.t("timing_puck_puck_time")
	var half_w := 240.0
	var slide_dist := 720.0
	puck_puck_banner.visible = true
	puck_puck_banner.modulate.a = 0.0
	puck_puck_banner.offset_left = -half_w - slide_dist
	puck_puck_banner.offset_right = half_w - slide_dist
	_banner_tween = create_tween()
	# Slower slide in from left to middle (1.15s)
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(puck_puck_banner, "offset_left", -half_w, 1.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(puck_puck_banner, "offset_right", half_w, 1.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(puck_puck_banner, "modulate:a", 1.0, 0.55)
	_banner_tween.set_parallel(false)
	# Stay in the middle longer (2.6s) so players can easily read the message
	_banner_tween.tween_interval(2.6)
	# Slower slide out from middle to right and disappear (1.15s)
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(puck_puck_banner, "offset_left", -half_w + slide_dist, 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_banner_tween.tween_property(puck_puck_banner, "offset_right", half_w + slide_dist, 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_banner_tween.tween_property(puck_puck_banner, "modulate:a", 0.0, 0.95)
	_banner_tween.set_parallel(false)
	_banner_tween.tween_callback(func() -> void: puck_puck_banner.visible = false)
