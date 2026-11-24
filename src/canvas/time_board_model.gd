class_name TimeBoardModel
extends RefCounted

## Pure logical model for the Time Board under the Fixed 12-Turn Action Cycle:
## - Maintains a fixed list of 6 persistent Action Tag objects (`_cycle_tags`),
##   one for each cycle step `[3, 4, 6, 8, 9, 12]`.
## - Each of the 6 tags tracks its own `turns` remaining (`0..12`), independent
##   of every other tag.
## - When a tag reaches the goal (`turns == 0`):
##   * If `count == 0`: it clears immediately (`turns` resets to `12`, off-bar)
##     without entering Action Time.
##   * If `count > 0`: it stays at `turns = 0` (standing at the goal) throughout
##     Action Time and Settle Time — its next-cycle replacement does NOT appear
##     until the goal tag disappears at the end of Action/Settle Time (when its
##     `turns` resets to `12`, ready to glide into slot 11 on the next Turn).
## - At Settle Time, settles damage (resetting Hit Level only at Turn 12 of the
##   12-turn cycle), removes defeated units from future tag counts, and resets
##   acted units' personal Action Countdown.

signal state_changed(new_state: Dictionary)

const SLOT_COUNT := 20
const BAR_SIZE := 10
const GOAL_SLOT := 19
const MAX_ENERGY := 20.0
const PREPARE_OPENING_ENERGY := 10.0
const CYCLE_LENGTH := 12
const CYCLE_TAG_STEPS: Array[int] = [3, 4, 6, 8, 9, 12]

var timing_manager: TimingManager = null
var unit_information_manager: UnitInformationManager = null
var unit_skill_manager: UnitSkillManager = null

var elapsed_turns: int = 0
var last_triggered_cycle_step: int = 0
var has_player_b: bool = false
var _turn_step_accum: float = 0.0
var _cycle_tags: Array[Dictionary] = []
var _tags: Dictionary = {}


func _init() -> void:
	_reset_cycle_tags()


func _reset_cycle_tags() -> void:
	_cycle_tags.clear()
	for i in range(CYCLE_TAG_STEPS.size()):
		var step: int = CYCLE_TAG_STEPS[i]
		_cycle_tags.append({
			"tag_index": i,
			"cycle_step": step,
			"turns": step,
			"count": 0,
			"is_cycle_12": (step == CYCLE_LENGTH),
		})


func bind(
	p_tm: TimingManager,
	p_uim: UnitInformationManager,
	p_usm: UnitSkillManager = null,
	p_has_player_b: bool = false
) -> void:
	_unbind()
	timing_manager = p_tm
	unit_information_manager = p_uim
	unit_skill_manager = p_usm
	has_player_b = p_has_player_b
	elapsed_turns = 0
	last_triggered_cycle_step = 0
	_turn_step_accum = 0.0
	_reset_cycle_tags()

	if unit_information_manager != null:
		unit_information_manager.current_cycle_turn = 0
		unit_information_manager.unit_registered.connect(_on_units_changed)
		unit_information_manager.unit_updated.connect(_on_units_changed)
		unit_information_manager.units_cleared.connect(_on_units_cleared)
		_initialize_unit_action_countdowns()

	if timing_manager != null:
		timing_manager.timing_changed.connect(_on_timing_changed)
		timing_manager.charge_slot_completed.connect(_on_charge_slot_completed)
		timing_manager.energy_changed.connect(_on_energy_changed)
		timing_manager.pause_changed.connect(_on_pause_changed)

	refresh_tags()


func _unbind() -> void:
	if timing_manager != null and is_instance_valid(timing_manager):
		if timing_manager.timing_changed.is_connected(_on_timing_changed):
			timing_manager.timing_changed.disconnect(_on_timing_changed)
		if timing_manager.charge_slot_completed.is_connected(_on_charge_slot_completed):
			timing_manager.charge_slot_completed.disconnect(_on_charge_slot_completed)
		if timing_manager.energy_changed.is_connected(_on_energy_changed):
			timing_manager.energy_changed.disconnect(_on_energy_changed)
		if timing_manager.pause_changed.is_connected(_on_pause_changed):
			timing_manager.pause_changed.disconnect(_on_pause_changed)
	if unit_information_manager != null and is_instance_valid(unit_information_manager):
		if unit_information_manager.unit_registered.is_connected(_on_units_changed):
			unit_information_manager.unit_registered.disconnect(_on_units_changed)
		if unit_information_manager.unit_updated.is_connected(_on_units_changed):
			unit_information_manager.unit_updated.disconnect(_on_units_changed)
		if unit_information_manager.units_cleared.is_connected(_on_units_cleared):
			unit_information_manager.units_cleared.disconnect(_on_units_cleared)


func set_has_player_b(value: bool) -> void:
	if has_player_b == value:
		return
	has_player_b = value
	state_changed.emit(get_state())


func is_frozen() -> bool:
	if timing_manager == null:
		return true
	if timing_manager.is_paused():
		return true
	return timing_manager.get_current_timing() != TimingManager.TIMING_CHARGING


func get_cycle_turn() -> int:
	if elapsed_turns <= 0:
		return 0
	return ((elapsed_turns - 1) % CYCLE_LENGTH) + 1


func get_cycle_tags() -> Array[Dictionary]:
	return _cycle_tags.duplicate(true)


func _initialize_unit_action_countdowns() -> void:
	if unit_information_manager == null:
		return
	for u in unit_information_manager.get_all_units():
		if u == null or u.is_dead or u.unit_kind == "boss":
			continue
		var cd := _sanitize_action_countdown(u.action_countdown)
		u.action_countdown = cd
		u.next_action_turns = cd
		u.action_tag_turns.clear()
		u.action_tag_turns.append(cd)
		unit_information_manager.unit_updated.emit(u)
	if unit_skill_manager != null:
		for u in unit_information_manager.get_all_units():
			if u == null:
				continue
			for sk in unit_skill_manager.get_unit_skills(u.unit_id):
				sk.reset_countdown_to_initial()


static func _sanitize_action_countdown(cd: int) -> int:
	if cd == 3 or cd == 4 or cd == 6:
		return cd
	return 4


func _on_units_changed(_u: UnitInformationDO = null) -> void:
	refresh_tags(false)


func _on_units_cleared() -> void:
	_reset_cycle_tags()
	refresh_tags()


func _on_timing_changed(new_timing: String, old_timing: String) -> void:
	if new_timing == TimingManager.TIMING_PREPARE:
		elapsed_turns = 0
		last_triggered_cycle_step = 0
		_turn_step_accum = 0.0
		_reset_cycle_tags()
		if unit_information_manager != null:
			unit_information_manager.current_cycle_turn = 0
		if timing_manager != null:
			timing_manager.set_energy(PREPARE_OPENING_ENERGY)
			if has_player_b:
				timing_manager.set_energy_b(PREPARE_OPENING_ENERGY)
		_initialize_unit_action_countdowns()
		refresh_tags()
		return

	if new_timing == TimingManager.TIMING_CHARGING and (old_timing == TimingManager.TIMING_ACTION or old_timing == TimingManager.TIMING_SETTLE):
		_clear_goal_tags_to_back_of_cycle()
		_reset_acted_unit_countdowns()
		refresh_tags()
		return

	state_changed.emit(get_state())


func _on_energy_changed(_new_energy: float, _charge_progress: float) -> void:
	state_changed.emit(get_state())


func _on_pause_changed(_paused: bool) -> void:
	state_changed.emit(get_state())


func _on_charge_slot_completed(_new_energy: float) -> void:
	var step := timing_manager.last_completed_step_amount if timing_manager != null else 1.0
	_turn_step_accum += step
	if _turn_step_accum < 1.0 - 0.001:
		state_changed.emit(get_state())
		return
	_turn_step_accum = maxf(0.0, _turn_step_accum - 1.0)
	_advance_one_turn()


func _clear_goal_tags_to_back_of_cycle() -> void:
	for i in range(_cycle_tags.size()):
		if int(_cycle_tags[i].get("turns", 12)) <= 0:
			_cycle_tags[i]["turns"] = CYCLE_LENGTH


func _advance_one_turn() -> void:
	elapsed_turns += 1
	last_triggered_cycle_step = ((elapsed_turns - 1) % CYCLE_LENGTH) + 1
	if unit_information_manager != null:
		unit_information_manager.current_cycle_turn = last_triggered_cycle_step

	if unit_skill_manager != null:
		unit_skill_manager.tick_all_skill_countdowns(1)

	# Any tag still at 0 wraps to 12 before stepping all 6 tags down by 1
	_clear_goal_tags_to_back_of_cycle()
	var reached_goal_idx := -1
	for i in range(_cycle_tags.size()):
		var t_rem := int(_cycle_tags[i].get("turns", 12)) - 1
		_cycle_tags[i]["turns"] = t_rem
		if t_rem == 0:
			reached_goal_idx = i

	var acting_count := 0
	if unit_information_manager != null:
		for u in unit_information_manager.get_all_units():
			if u == null or u.is_dead or u.unit_kind == "boss":
				continue
			var cd := _sanitize_action_countdown(u.action_countdown)
			u.action_countdown = cd
			u.next_action_turns = maxi(0, u.next_action_turns - 1)
			u.action_tag_turns.clear()
			u.action_tag_turns.append(u.next_action_turns if u.next_action_turns > 0 else 0)
			if u.next_action_turns == 0:
				acting_count += 1
			unit_information_manager.unit_updated.emit(u)

	if reached_goal_idx >= 0 and acting_count > 0:
		# Keep this tag at `turns = 0` (standing at the goal); its replacement does NOT appear yet!
		refresh_tags()
		if timing_manager != null and timing_manager.get_current_timing() == TimingManager.TIMING_CHARGING:
			timing_manager.enter_action_time()
	else:
		# 0-count tag reached the goal -> immediately disappears and wraps to turns = 12 without Action Time
		if reached_goal_idx >= 0:
			_cycle_tags[reached_goal_idx]["turns"] = CYCLE_LENGTH
		refresh_tags()


## Called when Settle Time resolves:
## - Settles all pending Damage Stacks (resetting Hit Level to 0 only when Turn 12 settles)
## - Disappears the firing goal tag (wrapping its `turns` from 0 to 12 so it glides into slot 11 on the next Turn)
## - Resets acted units' personal Action Countdown to their fixed interval
## - Updates future cycle tag counts (excluding newly defeated units)
func on_settle_time_resolved() -> Dictionary:
	var res := {}
	if unit_information_manager != null:
		unit_information_manager.current_cycle_turn = last_triggered_cycle_step
		res = unit_information_manager.settle_all_damage()
	_clear_goal_tags_to_back_of_cycle()
	_reset_acted_unit_countdowns()
	refresh_tags()
	return res


func _reset_acted_unit_countdowns() -> void:
	if unit_information_manager == null:
		return
	for u in unit_information_manager.get_all_units():
		if u == null or u.is_dead or u.unit_kind == "boss":
			continue
		var cd := _sanitize_action_countdown(u.action_countdown)
		u.action_countdown = cd
		if u.next_action_turns <= 0:
			u.next_action_turns = cd
			u.action_tag_turns.clear()
			u.action_tag_turns.append(cd)
			unit_information_manager.unit_updated.emit(u)


## Updates each of the 6 persistent tags' unit counts and rebuilds the slot map.
func refresh_tags(emit_signal_after: bool = true) -> void:
	if _cycle_tags.size() != CYCLE_TAG_STEPS.size():
		_reset_cycle_tags()
	_tags.clear()
	for i in range(_cycle_tags.size()):
		var step: int = int(_cycle_tags[i].get("cycle_step", CYCLE_TAG_STEPS[i]))
		var t_rem: int = clampi(int(_cycle_tags[i].get("turns", step)), 0, CYCLE_LENGTH)
		var unit_count := _count_units_acting_at_cycle_step(step)
		_cycle_tags[i]["count"] = unit_count
		_cycle_tags[i]["turns"] = t_rem
		_cycle_tags[i]["is_cycle_12"] = (step == CYCLE_LENGTH)
		var slot := GOAL_SLOT - t_rem
		_tags[slot] = {
			"tag_index": i,
			"count": unit_count,
			"turns": t_rem,
			"cycle_step": step,
			"is_cycle_12": (step == CYCLE_LENGTH),
		}

	if emit_signal_after:
		state_changed.emit(get_state())


func _count_units_acting_at_cycle_step(cycle_step: int) -> int:
	if unit_information_manager == null:
		return 0
	var total := 0
	for u in unit_information_manager.get_all_units():
		if u == null or u.is_dead or u.unit_kind == "boss":
			continue
		var cd := _sanitize_action_countdown(u.action_countdown)
		if cycle_step % cd == 0:
			total += 1
	return total


func get_unit_turns_to_goal(unit_id: String) -> int:
	if unit_information_manager == null:
		return 0
	var u := unit_information_manager.get_unit(unit_id)
	if u == null or u.is_dead or u.unit_kind == "boss":
		return 0
	return u.next_action_turns


func get_state() -> Dictionary:
	var e_a := timing_manager.get_energy() if timing_manager != null else 0.0
	var e_b := timing_manager.get_energy_b() if timing_manager != null else 0.0
	var ch := timing_manager.get_charge_progress() if timing_manager != null else 0.0
	return {
		"energy": e_a,
		"energy_a": e_a,
		"energy_b": e_b,
		"has_player_b": has_player_b,
		"charge": ch,
		"turn_progress": ch,
		"frozen": is_frozen(),
		"elapsed_turns": elapsed_turns,
		"cycle_turn": get_cycle_turn(),
		"cycle_tags": _cycle_tags.duplicate(true),
		"tags": _tags.duplicate(true),
		"action_tags": _tags.duplicate(true),
	}
