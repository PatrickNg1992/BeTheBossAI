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
	time_board.render_state({
		"energy": timing_manager.get_energy(),
		"energy_a": timing_manager.get_energy(),
		"energy_b": timing_manager.get_energy_b(),
		"has_player_b": has_player_b(),
		"charge": timing_manager.get_charge_progress(),
		"tags": {},
	})
	if is_host:
		sync_time_board({}, MpTransport.RELIABLE)
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
			if timing_manager.request_player_play(sender_role):
				active_player = sender_role
				sync_timing()
				sync_time_board({}, MpTransport.RELIABLE)
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
		data["action_tags"] = []
	if not data.has("unit_tag_turns"):
		data["unit_tag_turns"] = {}
	_dispatch_sync("time_board", data, transfer_mode)


func sync_boss_stats(payload: Dictionary = {}) -> void:
	if not is_host:
		return
	var data := payload.duplicate(true)
	_dispatch_sync("boss_stats", data, MpTransport.RELIABLE)


func sync_units(payload: Dictionary = {}) -> void:
	if not is_host:
		return
	var data := payload.duplicate(true)
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
				time_board.apply_state({
					"energy": energy_a,
					"energy_a": energy_a,
					"energy_b": energy_b,
					"has_player_b": two_p,
					"charge": progress,
					"action_tags": payload.get("action_tags", []),
				})
		"aiming":
			if cue_shot_manager != null and cue_shot_manager.has_method("apply_synced_aiming"):
				cue_shot_manager.apply_synced_aiming(payload)
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
	unit_information_manager.clear_all()
	var mode := UnitInformationManager.MODE_TWO_PLAYER_COOP if has_player_b() else UnitInformationManager.MODE_SINGLE_PLAYER
	unit_information_manager.configure_mode(mode)

	# 1. Register Player A Boss Monster (and Player B Boss Monster if present)
	if _player is BaseBossMonster:
		var boss_a := _player as BaseBossMonster
		unit_information_manager.register_boss("boss_a", "a", {
			"max_hp": 1000,
			"current_hp": 1000,
			"bars_remaining": 15,
			"max_bars": 15,
			"mass": boss_a.mass,
			"radius": boss_a.radius,
			"puck": boss_a,
		})
	var player_b := get_node_or_null("PlayerB") as BaseBossMonster
	if player_b != null:
		unit_information_manager.register_boss("boss_b", "b", {
			"max_hp": 1000,
			"current_hp": 1000,
			"bars_remaining": 15,
			"max_bars": 15,
			"mass": player_b.mass,
			"radius": player_b.radius,
			"puck": player_b,
		})

	# 2. Register Adventurer Team 1 (6 members: Enemy1..Enemy6, with ?5 and ?6 assigned random distinct classes)
	var all_classes: Array[int] = [
		EnemyAdventurer.AdventurerClass.WARRIOR,
		EnemyAdventurer.AdventurerClass.KNIGHT,
		EnemyAdventurer.AdventurerClass.MAGE,
		EnemyAdventurer.AdventurerClass.RANGER,
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
	timing_manager.set_paused(not timing_manager.is_paused())


func _on_action_button_pressed() -> void:
	_action_elapsed = 0.0
	timing_manager.enter_action_time()


func _on_timing_changed(new_timing: String, _old_timing: String) -> void:
	if new_timing == TimingManager.TIMING_PUCK_PUCK:
		_puck_puck_elapsed = 0.0
		_flash_puck_puck_banner()
	elif new_timing == TimingManager.TIMING_ACTION:
		_action_elapsed = 0.0
	elif new_timing == TimingManager.TIMING_SETTLE:
		if is_host and unit_information_manager != null:
			unit_information_manager.settle_all_damage()
	if is_host and (new_timing == TimingManager.TIMING_SETTLE or new_timing == TimingManager.TIMING_PREPARE):
		sync_puck_positions({}, MpTransport.RELIABLE)
	if is_host and new_timing == TimingManager.TIMING_CHARGING and _old_timing != TimingManager.TIMING_PLAY:
		timing_manager.reset_play_used()
		active_player = ""
	_refresh_controls()
	if is_host:
		sync_timing()


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
	if action_button != null:
		action_button.text = Loc.t("timing_action")
		action_button.disabled = paused or current == TimingManager.TIMING_ACTION


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


func _flash_puck_puck_banner() -> void:
	if puck_puck_banner == null:
		return
	if _banner_tween != null and _banner_tween.is_running():
		_banner_tween.kill()
	if banner_label != null:
		banner_label.text = Loc.t("timing_puck_puck_time")
	var half_w := 240.0
	var slide_dist := 720.0
	puck_puck_banner.visible = true
	puck_puck_banner.modulate.a = 0.0
	puck_puck_banner.offset_left = -half_w - slide_dist
	puck_puck_banner.offset_right = half_w - slide_dist
	_banner_tween = create_tween()
	# Slide in from left to middle (0.75s)
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(puck_puck_banner, "offset_left", -half_w, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(puck_puck_banner, "offset_right", half_w, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(puck_puck_banner, "modulate:a", 1.0, 0.35)
	_banner_tween.set_parallel(false)
	# Stay in the middle for 1.5s
	_banner_tween.tween_interval(1.5)
	# Slide out from middle to right and disappear (0.75s -> total 3.0s)
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(puck_puck_banner, "offset_left", -half_w + slide_dist, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_banner_tween.tween_property(puck_puck_banner, "offset_right", half_w + slide_dist, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_banner_tween.tween_property(puck_puck_banner, "modulate:a", 0.0, 0.65)
	_banner_tween.set_parallel(false)
	_banner_tween.tween_callback(func() -> void: puck_puck_banner.visible = false)
