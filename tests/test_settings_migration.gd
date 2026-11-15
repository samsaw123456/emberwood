extends "res://tests/test_game.gd"
## Changing the window title must not discard preferences or old records.


func _run() -> void:
	var legacy := OS.get_user_data_dir().get_base_dir().path_join("Emberwood — Forest Adventure")
	DirAccess.make_dir_recursive_absolute(legacy)
	var path := legacy.path_join("emberwood.cfg")
	var old := ConfigFile.new()
	old.set_value("settings", "muted", true)
	old.set_value("settings", "reduced_motion", true)
	old.set_value("game", ForestChapters.CAMPAIGN_BEST_KEY, 123.0)
	old.set_value("game", "six_guardians_best_time", 99.0)
	_check(old.save(path) == OK, "The fixture contains a previous-version save.")
	var original := FileAccess.get_file_as_string(path)
	game = MAIN.instantiate()
	root.add_child(game)
	await _step(3)
	_check(
		OS.get_user_data_dir().ends_with("Emberwood - Forest Adventure"),
		"The current app uses the ASCII-named data directory."
	)
	_check(
		game.sound.muted and game.reduced_motion,
		"The new app reads previous sound and motion settings."
	)
	_check(game.best_time == 123.0, "Compatible campaign records survive the app-name correction.")
	game._toggle_sound(false)
	var current := ConfigFile.new()
	_check(current.load(Adventure.SAVE_PATH) == OK, "A normal settings change writes the new save.")
	_check(not current.get_value("settings", "muted"), "The requested setting is updated.")
	_check(current.get_value("settings", "reduced_motion"), "Other preferences survive migration.")
	_check(
		current.get_value("game", "six_guardians_best_time") == 99.0,
		"Older campaign records are retained."
	)
	_check(FileAccess.get_file_as_string(path) == original, "The previous save stays intact.")
	game._load_settings()
	_check(not game.sound.muted, "The current file takes precedence over old preferences.")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: %d window-title settings migration checks." % checks)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
