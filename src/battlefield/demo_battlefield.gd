extends Node3D

## Demo battlefield root. Surfaces battle_finished so the Multiplayer Scene
## manager can swap everyone back to the Waiting Room when the battle ends.
## (Battle content and win/lose rules are the battle side's concern — this
## demo ends when the Boss Monster dies.)

signal battle_finished()

const PUCK_PUCK_PLACEHOLDER_SECONDS := 5.0
const ACTION_PLACEHOLDER_SECONDS := 5.0
const FAST_PLAY_SPEEDS: Array[float] = [1.0, 1.5, 2.0, 2.5]
const FAST_PLAY_LABELS: Array[String] = ["x1", "x1.5", "x2", "x2.5"]
const WOOD_PANEL_TEX: Texture2D = preload("res://src/resource/battlefield/wood_panel.png")
const SWORD_ICON_TEX: Texture2D = preload("res://src/resource/battlefield/sword.png")
const DOUBLE_ARROW_ICON_TEX: Texture2D = preload("res://src/resource/battlefield/double_arrow.png")

@onready var _player: Node3D = $Player
@onready var timing_manager: TimingManager = %TimingManager
@onready var time_board: TimeBoard = %TimeBoard
@onready var play_button: Button = %PlayButton
@onready var fast_play_button: Button = %FastPlayButton
@onready var pause_button: Button = %PauseButton
@onready var action_button: Button = %ActionButton
@onready var puck_puck_banner: TextureRect = %PuckPuckBanner
@onready var banner_label: Label = %BannerLabel

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


func _ready() -> void:
	if _player != null and _player.has_signal("died"):
		_player.died.connect(func() -> void: battle_finished.emit())

	var is_single_player := multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	timing_manager.set_single_player_mode(is_single_player)

	timing_manager.timing_changed.connect(_on_timing_changed)
	timing_manager.charge_slot_completed.connect(_on_charge_slot_completed)
	timing_manager.energy_changed.connect(_on_energy_changed)
	timing_manager.pause_changed.connect(_on_pause_changed)
	timing_manager.fast_play_changed.connect(_on_fast_play_changed)

	play_button.pressed.connect(_on_play_button_pressed)
	fast_play_button.pressed.connect(_on_fast_play_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	action_button.pressed.connect(_on_action_button_pressed)
	Loc.language_changed.connect(_update_ui_labels)

	time_board.render_state({
		"energy": timing_manager.get_energy(),
		"charge": timing_manager.get_charge_progress(),
		"tags": {},
	})
	_setup_control_styles()
	_update_ui_labels()
	_refresh_controls()


func _process(delta: float) -> void:
	if timing_manager == null or timing_manager.is_paused():
		return
	var current := timing_manager.get_current_timing()
	if current == TimingManager.TIMING_PUCK_PUCK:
		_puck_puck_elapsed += delta * timing_manager.get_effective_time_scale()
		if _puck_puck_elapsed >= PUCK_PUCK_PLACEHOLDER_SECONDS - 0.00001:
			_puck_puck_elapsed = 0.0
			timing_manager.notify_all_pucks_at_rest()
	elif current == TimingManager.TIMING_ACTION:
		_action_elapsed += delta * timing_manager.get_effective_time_scale()
		if _action_elapsed >= ACTION_PLACEHOLDER_SECONDS - 0.00001:
			_action_elapsed = 0.0
			timing_manager.notify_actions_finished()


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
		_puck_puck_elapsed = 0.0
		timing_manager.fire_cue_shot()


func _on_play_button_pressed() -> void:
	var current := timing_manager.get_current_timing()
	if current == TimingManager.TIMING_CHARGING:
		timing_manager.request_play()
	elif current == TimingManager.TIMING_PLAY:
		timing_manager.cancel_play()


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
	_refresh_controls()


func _on_charge_slot_completed(_new_energy: int) -> void:
	_refresh_controls()


func _on_energy_changed(new_energy: int, charge_progress: float) -> void:
	if time_board != null:
		time_board.apply_state({
			"energy": new_energy,
			"charge": charge_progress,
			"tags": {},
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
	if play_button != null:
		if current == TimingManager.TIMING_PLAY:
			play_button.text = Loc.t("timing_cancel")
			play_button.icon = null
			play_button.disabled = paused
			_apply_play_button_mode(true, paused)
		elif current == TimingManager.TIMING_CHARGING:
			play_button.text = Loc.t("timing_play")
			play_button.icon = SWORD_ICON_TEX
			var is_disabled := paused or not timing_manager.can_enter_play()
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
