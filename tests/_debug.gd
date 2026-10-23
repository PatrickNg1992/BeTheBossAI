extends Node

func _ready() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	await tree.process_frame
	var packed: PackedScene = load("res://src/canvas/time_board.tscn")
	var board = packed.instantiate()
	tree.root.add_child(board)
	board._start_demo()
	for i in range(46):
		board._demo_step()
	print("DEBUG demo state tags: ", board._demo_state.get("tags", {}))
	print("DEBUG energy: ", board._demo_state.get("energy", -1), " charge: ", board._demo_state.get("charge", -1))
	for slot in [10, 15, 16, 18, 19]:
		print("DEBUG slot ", slot, " tag_info: ", board.tag_info(slot))
	tree.quit(0)
