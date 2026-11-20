class_name TimingManager
extends Node

## Battle-scoped state machine owning the six Timings and all clock
## transition rules.

signal timing_changed(new_timing: String, old_timing: String)
signal charge_slot_completed(new_energy: float)
signal energy_changed(new_energy: float, charge_progress: float)
signal staged_damage_applied(applied_damage: Dictionary, settle_events: Array)
signal pause_changed(paused: bool)
signal fast_play_changed(enabled: bool)

const TIMING_PREPARE := "Prepare Time"
const TIMING_CHARGING := "Charging Time"
const TIMING_PLAY := "Play Time"
const TIMING_ACTION := "Action Time"
const TIMING_PUCK_PUCK := "Puck-puck Time!"
const TIMING_SETTLE := "Settle Time"

const MAX_ENERGY := 20.0

@export var turn_duration: float = 1.0
@export var settle_duration: float = 0.6
@export var fast_play_multiplier: float = 2.0
@export var single_player_mode: bool = true

var _current_timing: String = TIMING_CHARGING
var _energy: float = 0.0
var _energy_b: float = 0.0
var _charge_progress: float = 0.0
var _play_used_in_current_slot: bool = false
var _staged_damage: Dictionary = {}
var _settle_events: Array = []
var _settle_elapsed: float = 0.0
var _paused: bool = false
var _fast_play: bool = false


func _ready() -> void:
	add_to_group("timing_manager")


func _process(delta: float) -> void:
	advance_time(delta)


func get_current_timing() -> String:
	return _current_timing


func get_energy() -> float:
	return _energy


func get_energy_b() -> float:
	return _energy_b


func get_player_energy(seat: String) -> float:
	return _energy_b if seat == "b" else _energy


func set_energy_b(amount: float) -> void:
	_energy_b = clampf(snappedf(amount, 0.5), 0.0, MAX_ENERGY)
	energy_changed.emit(_energy, _charge_progress)


func set_player_energy(seat: String, amount: float) -> void:
	if seat == "b":
		set_energy_b(amount)
	else:
		set_energy(amount)


func consume_player_energy(seat: String, amount: float) -> float:
	if amount <= 0.0:
		return get_player_energy(seat)
	if seat == "b":
		set_energy_b(maxf(0.0, _energy_b - amount))
		return _energy_b
	return consume_energy(amount)


func get_charge_progress() -> float:
	return _charge_progress


func is_paused() -> bool:
	return _paused


func pause() -> void:
	set_paused(true)


func resume() -> void:
	set_paused(false)


func set_paused(value: bool) -> void:
	if _paused == value:
		return
	_paused = value
	pause_changed.emit(_paused)


func is_fast_play() -> bool:
	return _fast_play and single_player_mode


func set_single_player_mode(value: bool) -> void:
	if single_player_mode == value:
		return
	single_player_mode = value
	if not single_player_mode and _fast_play:
		_fast_play = false
		fast_play_changed.emit(false)


func set_fast_play(enabled: bool) -> bool:
	if enabled and not single_player_mode:
		return false
	if _fast_play == enabled:
		return true
	_fast_play = enabled
	fast_play_changed.emit(_fast_play)
	return true


func get_effective_time_scale() -> float:
	if _paused:
		return 0.0
	if not is_fast_play():
		return 1.0
	match _current_timing:
		TIMING_CHARGING, TIMING_ACTION, TIMING_PUCK_PUCK, TIMING_SETTLE:
			return maxf(fast_play_multiplier, 1.0)
		_:
			return 1.0


func can_enter_play() -> bool:
	return not _paused and _current_timing == TIMING_CHARGING and not _play_used_in_current_slot


func enter_prepare() -> bool:
	if _paused:
		return false
	_charge_progress = 0.0
	_play_used_in_current_slot = false
	_transition_to(TIMING_PREPARE)
	return true


func start_charging() -> bool:
	if _paused:
		return false
	_transition_to(TIMING_CHARGING)
	return true


func request_play() -> bool:
	if not can_enter_play():
		return false
	_play_used_in_current_slot = true
	_transition_to(TIMING_PLAY)
	return true


func cancel_play() -> bool:
	if _paused or _current_timing != TIMING_PLAY:
		return false
	_transition_to(TIMING_CHARGING)
	return true


func enter_action_time() -> bool:
	if _paused or _current_timing == TIMING_ACTION:
		return false
	_transition_to(TIMING_ACTION)
	return true


func fire_cue_shot(energy_cost: float = 0.0) -> bool:
	if _paused:
		return false
	if _current_timing != TIMING_PLAY and _current_timing != TIMING_ACTION:
		return false
	if energy_cost > 0.0:
		consume_energy(energy_cost)
	_transition_to(TIMING_PUCK_PUCK)
	return true


func play_card(target_timing: String = TIMING_CHARGING, energy_cost: float = 0.0) -> bool:
	if _paused or _current_timing != TIMING_PLAY:
		return false
	if target_timing != TIMING_CHARGING and target_timing != TIMING_ACTION and target_timing != TIMING_PUCK_PUCK:
		return false
	if energy_cost > 0.0:
		consume_energy(energy_cost)
	_transition_to(target_timing)
	return true


func consume_energy(amount: float) -> float:
	if amount <= 0.0:
		return _energy
	set_energy(maxf(0.0, _energy - amount))
	return _energy


func stage_damage(target_id: Variant, amount: int) -> void:
	if amount <= 0:
		return
	var current: int = _staged_damage.get(target_id, 0)
	_staged_damage[target_id] = current + amount


func get_staged_damage() -> Dictionary:
	return _staged_damage.duplicate(true)


func get_staged_damage_for(target_id: Variant) -> int:
	return _staged_damage.get(target_id, 0)


func record_settle_event(event: Variant) -> void:
	_settle_events.append(event)


func has_settle_worthy_events() -> bool:
	return not _staged_damage.is_empty() or not _settle_events.is_empty()


func notify_all_pucks_at_rest() -> bool:
	if _paused or _current_timing != TIMING_PUCK_PUCK:
		return false
	_resolve_to_settle_or_charging()
	return true


func notify_actions_finished() -> bool:
	if _paused or _current_timing != TIMING_ACTION:
		return false
	_resolve_to_settle_or_charging()
	return true


func notify_settle_finished() -> bool:
	if _paused or _current_timing != TIMING_SETTLE:
		return false
	_settle_elapsed = 0.0
	_transition_to(TIMING_CHARGING)
	return true


func set_energy(amount: float) -> void:
	_energy = clampf(snappedf(amount, 0.5), 0.0, MAX_ENERGY)
	if _energy >= MAX_ENERGY:
		_charge_progress = 0.0
	energy_changed.emit(_energy, _charge_progress)


func advance_time(delta: float) -> void:
	if _paused or delta <= 0.0:
		return
	var scaled_delta := delta * get_effective_time_scale()
	if _current_timing == TIMING_CHARGING:
		var duration := maxf(turn_duration, 0.0001)
		_charge_progress += scaled_delta / duration
		while true:
			var step_needed := _next_charge_step_needed()
			if _charge_progress < step_needed - 0.00001:
				break
			_charge_progress = maxf(_charge_progress - step_needed, 0.0)
			if _charge_progress < 0.00001:
				_charge_progress = 0.0
			_finish_charge_step(step_needed)
		energy_changed.emit(_energy, _charge_progress)
	elif _current_timing == TIMING_SETTLE and settle_duration > 0.0:
		_settle_elapsed += scaled_delta
		if _settle_elapsed >= settle_duration - 0.00001:
			notify_settle_finished()


func complete_charge_slot() -> void:
	if _paused or _current_timing != TIMING_CHARGING:
		return
	var step_needed := _next_charge_step_needed()
	_charge_progress = 0.0
	_finish_charge_step(step_needed)
	energy_changed.emit(_energy, _charge_progress)


func _next_charge_step_needed() -> float:
	var frac_a := fposmod(_energy, 1.0)
	var frac_b := fposmod(_energy_b, 1.0)
	if (frac_a > 0.25 and frac_a < 0.75) or (frac_b > 0.25 and frac_b < 0.75):
		return 0.5
	return 1.0


func _finish_charge_step(step_amount: float) -> void:
	if _energy < MAX_ENERGY:
		_energy = minf(MAX_ENERGY, snappedf(_energy + step_amount, 0.5))
	if _energy_b < MAX_ENERGY:
		_energy_b = minf(MAX_ENERGY, snappedf(_energy_b + step_amount, 0.5))
	_play_used_in_current_slot = false
	charge_slot_completed.emit(_energy)


func _resolve_to_settle_or_charging() -> void:
	if has_settle_worthy_events():
		_settle_elapsed = 0.0
		_transition_to(TIMING_SETTLE)
		var dmg := _staged_damage.duplicate(true)
		var ev := _settle_events.duplicate(true)
		_staged_damage.clear()
		_settle_events.clear()
		staged_damage_applied.emit(dmg, ev)
	else:
		_transition_to(TIMING_CHARGING)


func _transition_to(new_timing: String) -> void:
	if _current_timing == new_timing:
		return
	var old_timing := _current_timing
	_current_timing = new_timing
	timing_changed.emit(_current_timing, old_timing)
