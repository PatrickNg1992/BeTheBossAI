extends Node

## Headless test bootstrap. Mirrors the editor MCP runner's discovery:
## loads every res://tests/test_*.gd McpTestSuite and runs them.
## Run with: godot --headless --path <project> tests/_run_all.tscn
## Exit code 1 when any test fails or a suite fails to load.

func _ready() -> void:
	## Capture the tree now: a test that navigates scenes frees this node,
	## so get_tree() would fail after the suites run.
	var tree := Engine.get_main_loop() as SceneTree
	## Tree root is still busy during _ready; defer suite execution by one
	## frame so tests can add/remove their own children safely.
	await tree.process_frame
	var suites: Array = []
	var errors: Array[String] = []
	var dir := DirAccess.open("res://tests")
	if dir == null:
		errors.append("DirAccess.open('res://tests') returned null — directory may not exist")
	else:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if file_name.begins_with("test_") and file_name.ends_with(".gd"):
				var path := "res://tests/" + file_name
				var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
				if script == null:
					errors.append("%s (load failed — check for parse errors or duplicate methods)" % file_name)
				elif script.can_instantiate():
					var instance = script.new()
					if instance is McpTestSuite:
						suites.append(instance)
					else:
						errors.append("%s (not a McpTestSuite subclass)" % file_name)
				else:
					errors.append("%s (cannot instantiate — abstract or broken)" % file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	var runner := McpTestRunner.new()
	var results := runner.run_suites(suites)
	if not errors.is_empty():
		results["load_errors"] = errors
	print("TEST_RESULTS:" + JSON.stringify(results))
	var failed_count: int = results.get("failed", 0)
	if not errors.is_empty():
		failed_count += 1
	var exit_code := 1 if failed_count > 0 else 0
	tree.quit(exit_code)
