class_name UnitInformationBoard
extends Control

## The Unit Information Board HUD on the left and right edges of the battlefield
## canvas: two 2-column x 8-row grids ({L|R}{Row 1..8}{Col 1..2}) of UnitDisplay
## cells (or 2-column horizontal spans for Boss Monsters and Adventurer Team headers).
## Listens to events from UnitInformationManager and renders unit portraits,
## Reference Marks, Class Marks, Boss Frenzy Power, and HP bars.

var manager: UnitInformationManager = null
var local_role: String = "a"

var _left_host: Container = null
var _right_host: Container = null
var _left_rows: Dictionary = {} # row (1..8) -> HBoxContainer
var _right_rows: Dictionary = {} # row (1..8) -> HBoxContainer
var _cells: Dictionary = {} # grid_id ("L11".."L82", "R11".."R82") -> UnitDisplay
var _detail_display: UnitDetailDisplay = null
var _hovered_grid_id: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ensure_detail_display()
	if Loc != null and not Loc.language_changed.is_connected(refresh_board):
		Loc.language_changed.connect(refresh_board)


func _ensure_detail_display() -> void:
	if _detail_display == null or not is_instance_valid(_detail_display):
		_detail_display = UnitDetailDisplay.new()
		_detail_display.name = "UnitDetailDisplay"
		add_child(_detail_display)


## Attaches the board's Left and Right 8-row grids into existing left/right
## container nodes on the Canvas (e.g. LeftUnitList and RightUnitList), or creates
## internal containers when instantiated standalone in unit tests.
func attach_to_containers(left_container: Container, right_container: Container) -> void:
	for child in get_children():
		if child == _detail_display:
			continue
		remove_child(child)
		child.queue_free()
	_cells.clear()
	_ensure_detail_display()
	_left_host = left_container
	_right_host = right_container
	_build_grid_into(_left_host, "L", _left_rows)
	_build_grid_into(_right_host, "R", _right_rows)
	refresh_board()


func _ensure_internal_hosts() -> void:
	if _left_host == null:
		var l_vbox := VBoxContainer.new()
		l_vbox.name = "InternalLeftGrid"
		add_child(l_vbox)
		_left_host = l_vbox
		_build_grid_into(_left_host, "L", _left_rows)
	if _right_host == null:
		var r_vbox := VBoxContainer.new()
		r_vbox.name = "InternalRightGrid"
		add_child(r_vbox)
		_right_host = r_vbox
		_build_grid_into(_right_host, "R", _right_rows)


func _build_grid_into(host: Container, side: String, rows_dict: Dictionary) -> void:
	if host == null:
		return
	for child in host.get_children():
		host.remove_child(child)
		child.queue_free()
	rows_dict.clear()
	if host is BoxContainer:
		host.add_theme_constant_override("separation", 4)
	for r in range(1, 9):
		var row_box := HBoxContainer.new()
		row_box.name = "Row_%s%d" % [side, r]
		row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row_box.add_theme_constant_override("separation", 4)
		row_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(row_box)
		rows_dict[r] = row_box

		for c in range(1, 3):
			var gid := "%s%d%d" % [side, r, c]
			var cell := UnitDisplay.new(gid, 1)
			cell.name = "Cell_%s" % gid
			cell.cell_hovered.connect(_on_cell_hovered)
			cell.cell_clicked.connect(_on_cell_clicked)
			row_box.add_child(cell)
			_cells[gid] = cell


func bind_manager(p_manager: UnitInformationManager) -> void:
	if _cells.is_empty():
		_ensure_internal_hosts()
	if manager != null and is_instance_valid(manager):
		if manager.unit_registered.is_connected(_on_unit_changed):
			manager.unit_registered.disconnect(_on_unit_changed)
		if manager.unit_updated.is_connected(_on_unit_changed):
			manager.unit_updated.disconnect(_on_unit_changed)
		if manager.units_cleared.is_connected(refresh_board):
			manager.units_cleared.disconnect(refresh_board)
		if manager.mode_changed.is_connected(_on_mode_changed):
			manager.mode_changed.disconnect(_on_mode_changed)
		if manager.unit_damage_pushed.is_connected(_on_unit_damage_pushed):
			manager.unit_damage_pushed.disconnect(_on_unit_damage_pushed)
		if manager.unit_collision_impulse_received.is_connected(_on_unit_collision_impulse_received):
			manager.unit_collision_impulse_received.disconnect(_on_unit_collision_impulse_received)
		if manager.frenzy_power_spread_started.is_connected(_on_frenzy_power_spread_started):
			manager.frenzy_power_spread_started.disconnect(_on_frenzy_power_spread_started)
		if manager.damage_settled.is_connected(_on_damage_settled):
			manager.damage_settled.disconnect(_on_damage_settled)
		if manager.unit_skill_triggered.is_connected(_on_unit_skill_triggered):
			manager.unit_skill_triggered.disconnect(_on_unit_skill_triggered)
	manager = p_manager
	if manager != null:
		manager.unit_registered.connect(_on_unit_changed)
		manager.unit_updated.connect(_on_unit_changed)
		manager.units_cleared.connect(refresh_board)
		manager.mode_changed.connect(_on_mode_changed)
		manager.unit_damage_pushed.connect(_on_unit_damage_pushed)
		manager.unit_collision_impulse_received.connect(_on_unit_collision_impulse_received)
		manager.frenzy_power_spread_started.connect(_on_frenzy_power_spread_started)
		manager.damage_settled.connect(_on_damage_settled)
		manager.unit_skill_triggered.connect(_on_unit_skill_triggered)
	refresh_board()


func _on_unit_damage_pushed(u: UnitInformationDO, dmg_do: DamageDO) -> void:
	if u == null or dmg_do == null:
		return
	var cell := _cells.get(u.grid_id, null) as UnitDisplay
	if cell != null:
		cell.render_unit(u, local_role)
		cell.trigger_damage_badge_shake(dmg_do.value)


func _on_unit_collision_impulse_received(u: UnitInformationDO, impulse_magnitude: float) -> void:
	if u == null:
		return
	var cell := _cells.get(u.grid_id, null) as UnitDisplay
	if cell != null:
		cell.trigger_collision_impulse_shake(impulse_magnitude)


func _on_frenzy_power_spread_started(settled_records: Dictionary) -> void:
	if manager == null:
		return
	for uid in settled_records.keys():
		var u := manager.get_unit(str(uid))
		if u != null and u.unit_kind == "enemy_adventurer":
			var cell := _cells.get(u.grid_id, null) as UnitDisplay
			if cell != null:
				cell.play_frenzy_spread_effect()


func _on_damage_settled(settled_records: Dictionary) -> void:
	if manager == null:
		return
	for uid in settled_records.keys():
		var dmg := int(settled_records.get(uid, 0))
		if dmg <= 0:
			continue
		var u := manager.get_unit(str(uid))
		if u != null:
			var cell := _cells.get(u.grid_id, null) as UnitDisplay
			if cell != null:
				cell.show_settled_hp_change(dmg)


func _on_unit_skill_triggered(u: UnitInformationDO, skill_text: String) -> void:
	if u == null:
		return
	var cell := _cells.get(u.grid_id, null) as UnitDisplay
	if cell != null:
		cell.show_skill_popup(skill_text)


func _on_cell_hovered(grid_id: String, hovered: bool) -> void:
	simulate_cell_hover(grid_id, hovered)


func _on_cell_clicked(grid_id: String) -> void:
	simulate_cell_click(grid_id)


func _is_aim_dragging_active() -> bool:
	var parent := get_parent()
	while parent != null:
		var csm := parent.get_node_or_null("CueShotManager")
		if csm != null and csm.has_method("is_dragging"):
			return bool(csm.call("is_dragging"))
		parent = parent.get_parent()
	if is_inside_tree():
		for node in get_tree().root.find_children("CueShotManager", "", true, false):
			if node != null and node.has_method("is_dragging") and bool(node.call("is_dragging")):
				return true
	return false


func _clear_all_hover_highlights() -> void:
	_hovered_grid_id = ""
	for cell_val in _cells.values():
		var c := cell_val as UnitDisplay
		if c != null:
			c.set_hover_highlighted(false)
	if manager != null:
		for u in manager.get_all_units():
			manager.set_unit_highlighted(u.unit_id, false)


func simulate_cell_hover(grid_id: String, hovered: bool) -> void:
	if hovered and _is_aim_dragging_active():
		_clear_all_hover_highlights()
		return
	var cell := _cells.get(grid_id, null) as UnitDisplay
	if cell != null:
		cell.set_hover_highlighted(hovered)
	if manager == null:
		return
	var u := manager.get_unit_at_grid(grid_id)
	if u == null:
		return
	_hovered_grid_id = grid_id if hovered else ""
	manager.set_unit_highlighted(u.unit_id, hovered)


func simulate_cell_click(grid_id: String) -> void:
	if _is_aim_dragging_active():
		return
	_ensure_detail_display()
	if manager == null:
		_detail_display.close_popup()
		return
	var u := manager.get_unit_at_grid(grid_id)
	if u == null:
		_detail_display.close_popup()
		return
	if _detail_display.visible and _detail_display.inspected_grid_id == grid_id:
		_detail_display.close_popup()
	else:
		_detail_display.show_for_unit(u, grid_id)


func close_detail_display() -> void:
	if _detail_display != null:
		_detail_display.close_popup()


func is_detail_display_open() -> bool:
	return _detail_display != null and _detail_display.visible


func get_detail_display_info() -> Dictionary:
	_ensure_detail_display()
	return _detail_display.get_info()


func _input(event: InputEvent) -> void:
	if not is_detail_display_open():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var pos := mb.position
			if _detail_display.get_global_rect().has_point(pos):
				return
			for cell_val in _cells.values():
				var cell := cell_val as UnitDisplay
				if cell != null and cell.visible and cell.is_occupied and cell.get_global_rect().has_point(pos):
					return
			close_detail_display()


func set_local_role(p_role: String) -> void:
	local_role = p_role
	refresh_board()


func _on_unit_changed(_u: UnitInformationDO) -> void:
	refresh_board()
	if _detail_display != null and _detail_display.visible and _detail_display.inspected_unit != null:
		_detail_display.show_for_unit(_detail_display.inspected_unit, _detail_display.inspected_grid_id)


func _on_mode_changed(_new_mode: String) -> void:
	refresh_board()


func refresh_board() -> void:
	if _cells.is_empty():
		_ensure_internal_hosts()
	for side in ["L", "R"]:
		for r in range(1, 9):
			_refresh_row(side, r)


func _refresh_row(side: String, r: int) -> void:
	var gid1 := "%s%d1" % [side, r]
	var gid2 := "%s%d2" % [side, r]
	var cell1 := _cells.get(gid1, null) as UnitDisplay
	var cell2 := _cells.get(gid2, null) as UnitDisplay
	if cell1 == null or cell2 == null:
		return

	if manager == null:
		cell1.span_cols = 1
		cell2.visible = true
		cell1.set_empty()
		cell2.set_empty()
		return

	# Check if Row R1 or R5 is an Adventurer Team header in Single-Player or 2P Co-op
	if side == "R" and manager.game_mode != UnitInformationManager.MODE_TWO_PLAYER_VS:
		if r == 1:
			cell1.span_cols = 2
			cell2.visible = false
			cell1.set_team_header(manager.get_team_header_key(1), 1)
			return
		elif r == 5:
			cell1.span_cols = 2
			cell2.visible = false
			cell1.set_team_header(manager.get_team_header_key(2), 2)
			return

	var u1 := manager.get_unit_at_grid(gid1)
	var row_box := _left_rows.get(r, null) as Control if side == "L" else _right_rows.get(r, null) as Control
	if u1 != null and u1.span_cols == 2:
		if row_box != null:
			row_box.size_flags_stretch_ratio = 1.4
		cell1.span_cols = 2
		cell2.visible = false
		cell1.render_unit(u1, local_role)
		return

	if row_box != null:
		row_box.size_flags_stretch_ratio = 1.0

	cell1.span_cols = 1
	cell2.visible = true
	if u1 != null:
		cell1.render_unit(u1, local_role)
	else:
		cell1.set_empty()

	var u2 := manager.get_unit_at_grid(gid2)
	if u2 != null:
		cell2.render_unit(u2, local_role)
	else:
		cell2.set_empty()


func get_cell_info(grid_id: String) -> Dictionary:
	var cell := _cells.get(grid_id, null) as UnitDisplay
	if cell == null:
		return {"grid_id": grid_id, "occupied": false, "is_team_header": false}
	return cell.get_info()


func get_unit_display(grid_id: String) -> UnitDisplay:
	return _cells.get(grid_id, null) as UnitDisplay
