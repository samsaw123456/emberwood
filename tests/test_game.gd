extends SceneTree
## Runs the real scene with isolated settings. See tools/run_game_tests.py.

const Adventure := preload("res://scripts/game.gd")
const MAIN := preload("res://scenes/main.tscn")

var game: Node2D
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	var isolated := OS.get_environment("EMBERWOOD_TEST_DATA_DIR")
	if (
		isolated.is_empty()
		or OS.get_environment("XDG_DATA_HOME") != isolated
		or not OS.get_user_data_dir().begins_with(isolated + "/")
	):
		push_error("Set XDG_DATA_HOME and EMBERWOOD_TEST_DATA_DIR to a temporary test directory.")
		quit(2)
		return
	call_deferred(&"_run")


func _run() -> void:
	game = MAIN.instantiate()
	root.add_child(game)
	await _step(3)
	await _test_start_pause_input()
	await _test_contacts_and_retry()
	await _test_pause_during_retry()
	await _test_chapters_and_boss()
	await _test_settings_reload()
	await _test_save_merging()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: %d game integration checks." % checks)
		print("HUD, keys, physics contacts, checkpoints, chapters, boss, pause, replay, settings.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _test_start_pause_input() -> void:
	_check(game.state == Adventure.State.TITLE, "The main scene opens on its title screen.")
	_check(not game.fox.active and not game.level.active, "The title freezes the adventure.")
	_check(game.elapsed == 0.0, "Title time is not counted as adventure time.")
	_check(game.best_time == 0.0, "An absent save starts without a time record.")
	_check(not game.sound.muted, "An absent save enables sound by default.")
	_check(not game.reduced_motion, "An absent save uses normal motion by default.")
	for pair: Array in [
		["move_left", KEY_LEFT],
		["move_left", KEY_A],
		["move_right", KEY_RIGHT],
		["move_right", KEY_D],
		["jump", KEY_UP],
		["jump", KEY_W],
		["jump", KEY_SPACE],
		["pause", KEY_ESCAPE],
		["pause", KEY_P],
		["retry", KEY_R],
		["mute", KEY_M],
		["dash", KEY_SHIFT],
		["shoot", KEY_J]
	]:
		var mapped := false
		for event: InputEvent in InputMap.action_get_events(pair[0]):
			if event is InputEventKey and event.physical_keycode == pair[1]:
				mapped = true
		_check(mapped, "Action %s maps to %s." % [pair[0], OS.get_keycode_string(pair[1])])
	_press_button("Start adventure")
	_check(game.state == Adventure.State.PLAYING, "The title button starts the adventure.")
	await _step(8)
	var start_x: float = game.fox.position.x
	_key(KEY_RIGHT, true)
	await _step(12)
	_key(KEY_RIGHT, false)
	_check(game.fox.position.x > start_x + 20.0, "A real Right key event moves right.")
	_key(KEY_LEFT, true)
	await _step(24)
	_key(KEY_LEFT, false)
	_check(game.fox.position.x < start_x, "A real Left key event moves left.")
	_press_button("Ⅱ")
	_check(game.state == Adventure.State.PAUSED, "The HUD pause button pauses the adventure.")
	var stopped_time: float = game.elapsed
	var stopped_age: float = game.level.age
	var stopped_fox: Vector2 = game.fox.position
	var platform: ForestPlatform = _platform_of_kind("moving")
	# AnimatableBody2D commits the previous tick's transform at the next physics sync.
	await _step(1)
	var stopped_platform := platform.position
	await _step(12)
	_check(game.elapsed == stopped_time, "Pause freezes the adventure timer.")
	_check(game.level.age == stopped_age, "Pause freezes critter and collectible time.")
	_check(game.fox.position == stopped_fox, "Pause freezes the fox's physics.")
	_check(
		platform.position == stopped_platform,
		"Pause freezes moving platforms: %s -> %s." % [stopped_platform, platform.position]
	)
	_press_button("Keep exploring")
	await _step(3)
	_check(game.state == Adventure.State.PLAYING, "The resume button continues the adventure.")
	_check(game.elapsed > stopped_time, "The adventure timer resumes.")


func _test_contacts_and_retry() -> void:
	await _touch(game.level.gems[0])
	_check(game.level.taken_gems.size() == 1, "Contact collects a gem.")
	await _step(5)
	_check(game.level.taken_gems.size() == 1, "Repeated gem contact cannot award it twice.")
	await _touch(game.level.acorns[0])
	_check(game.level.taken_acorns.size() == 1, "Contact collects a magic acorn.")
	await _step(5)
	_check(game.level.taken_acorns.size() == 1, "Repeated acorn contact cannot award it twice.")
	await _touch(game.level.secret)
	_check(game.level.secret_found, "Contact discovers the hidden firefly.")
	game.fox.reset_at(game.level.camps[1])
	await _step(3)
	_check(game.level.camp_index == 1, "Touching a later campfire saves the checkpoint.")
	var treasure: int = game.level.taken_gems.size()
	game.level.critters[0].out = true
	game.invincible_left = 0.0
	var spike: Rect2 = game.level.spikes[0]
	game.fox.reset_at(Vector2(spike.get_center().x, ForestLevel.FLOOR_Y))
	await _step(2)
	_check(game.state == Adventure.State.RESPAWNING, "Spike contact starts a retry.")
	_check(game.deaths == 1, "Continuous spike contact counts only one retry.")
	var stopped_time: float = game.elapsed
	await _step(10)
	_check(game.elapsed == stopped_time, "The retry animation does not add adventure time.")
	await _step(48)
	_check(game.state == Adventure.State.PLAYING, "Retry automatically returns to play.")
	_check(
		game.fox.position.distance_to(game.level.camps[1]) < 1.0,
		"Retry returns to the lit campfire on safe ground."
	)
	_check(game.level.taken_gems.size() == treasure, "Retry preserves collected gems.")
	_check(game.level.taken_acorns.size() == 1, "Retry preserves collected acorns.")
	_check(game.level.secret_found, "Retry preserves the firefly discovery.")
	_check(not game.level.critters[0].out, "Retry restores critters.")
	_check(game.invincible_left > 0.0, "Respawning grants a short safe grace period.")
	game.fox.reset_at(Vector2(2200.0, 760.0))
	await _step(2)
	_check(game.state == Adventure.State.RESPAWNING, "Falling below the world starts a retry.")
	_check(game.deaths == 2, "A fall adds one retry even during the grace period.")
	await _step(55)
	_check(game.state == Adventure.State.PLAYING, "A fall recovers without restarting the app.")
	_check(game.level.camp_index == 1, "A fall keeps the checkpoint.")


func _test_pause_during_retry() -> void:
	_key(KEY_R, true)
	_key(KEY_R, false)
	await _step(8)
	_check(game.state == Adventure.State.RESPAWNING, "The R key starts a checkpoint retry.")
	_key(KEY_ESCAPE, true)
	_key(KEY_ESCAPE, false)
	await _step(1)
	_check(game.state == Adventure.State.PAUSED, "Escape can pause midway through a retry.")
	var countdown: float = game.respawn_left
	var stopped_time: float = game.elapsed
	await _step(65)
	_check(game.state == Adventure.State.PAUSED, "A paused retry cannot resume on its own.")
	_check(game.respawn_left == countdown, "Pause preserves the remaining retry countdown.")
	_check(game.elapsed == stopped_time, "Adventure time stays frozen during a paused retry.")
	_press_button("Keep exploring")
	_check(game.state == Adventure.State.RESPAWNING, "Resume restores the unfinished retry state.")
	await _step(55)
	_check(game.state == Adventure.State.PLAYING, "The resumed retry finishes safely.")
	_check(
		game.fox.position.distance_to(game.level.camps[1]) < 1.0,
		"Resuming a retry still lands at the saved checkpoint."
	)
	game.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(game.state == Adventure.State.PAUSED, "Losing focus during play pauses the adventure.")
	game.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	await _step(3)
	_check(game.state == Adventure.State.PAUSED, "Regaining focus waits for an explicit resume.")
	_press_button("Keep exploring")
	_key(KEY_R, true)
	_key(KEY_R, false)
	await _step(8)
	game.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(game.state == Adventure.State.PAUSED, "Losing focus also pauses an unfinished retry.")
	countdown = game.respawn_left
	await _step(65)
	_check(
		game.state == Adventure.State.PAUSED, "An unfocused retry stays paused past its deadline."
	)
	_check(game.respawn_left == countdown, "Focus loss freezes the retry countdown.")
	game.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	_press_button("Keep exploring")
	_check(game.state == Adventure.State.RESPAWNING, "Focus recovery resumes the unfinished retry.")
	await _step(55)
	_check(game.state == Adventure.State.PLAYING, "Focus recovery safely completes the retry.")


func _test_chapters_and_boss() -> void:
	game.fox.reset_at(game.level.gate)
	await _step(3)
	_check(game.state == Adventure.State.PLAYING, "The first gate requires the missing acorns.")
	_check(game.gate_hint_cooldown > 0.0, "A locked gate explains what is missing.")
	for index: int in range(1, game.level.acorns.size()):
		await _touch(game.level.acorns[index])
	game.fox.reset_at(game.level.gate)
	await _step(3)
	_check(game.state == Adventure.State.CHAPTER_COMPLETE, "The forest gate finishes chapter one.")
	_check(not game.fox.active and not game.level.active, "A chapter result freezes hazards.")
	_check(game.best_time == 0.0, "A partial campaign cannot replace the full campaign record.")
	_check(game.chapter_results.size() == 1, "The completed chapter records its treasure once.")
	var elapsed: float = game.elapsed
	await _step(5)
	_check(game.elapsed == elapsed, "Chapter results do not consume adventure time.")
	var previous_level: ForestLevel = game.level
	_press_button("Continue")
	game.hud.next_requested.emit()
	_check(game.stage_index == 1, "Repeated Continue input advances only one chapter.")
	_check(game.state == Adventure.State.PLAYING, "Continue starts the Flooded Mill.")
	_check(game.level.title == "Flooded Mill", "Chapter two uses the new mill layout.")
	_check(game.level.taken_acorns.is_empty(), "Each new chapter has fresh acorns.")
	_check(game.level.camp_index == 0, "A new chapter starts at its own first campfire.")
	_check(game.fox.position == game.level.camps[0], "The fox starts on safe new-chapter ground.")
	_check(game.elapsed == elapsed, "Continue retains cumulative campaign time.")
	_check(game.camera_x == 0, "A new chapter resets the camera to its entrance.")
	await _step(3)
	_check(not is_instance_valid(previous_level), "Changing chapters frees the old world.")
	await _collect_acorns()
	game.fox.reset_at(game.level.gate)
	await _step(3)
	_check(game.state == Adventure.State.CHAPTER_COMPLETE, "The mill gate finishes chapter two.")
	_check(game.chapter_results.size() == 2, "Both completed chapters contribute to the result.")
	_press_button("Continue")
	_check(
		game.stage_index == 2 and is_instance_valid(game.boss), "High Canopy includes Old Croak."
	)
	_check(not game.boss.engaged, "The boss waits before the fox reaches its clearing.")
	game.fox.reset_at(game.level.gate)
	await _step(3)
	_check(not game.boss_started, "Missing acorns cannot start a fight that traps the fox.")
	_check(not is_instance_valid(game.arena_wall), "The route back stays open with missing acorns.")
	_check(game.state == Adventure.State.PLAYING, "The final gate is locked before the fight.")
	await _collect_acorns()
	game.fox.reset_at(Vector2(2660, ForestLevel.FLOOR_Y))
	await _step(3)
	_check(game.boss_started and game.boss.engaged, "Three acorns and arena entry start the boss.")
	_check(
		is_instance_valid(game.arena_wall), "The arena closes only after required treasure is safe."
	)
	_check(
		game.level.camp_index == game.level.camps.size() - 1, "The fight saves an arena checkpoint."
	)
	game.fox.reset_at(game.level.gate)
	await _step(3)
	_check(
		game.state == Adventure.State.PLAYING, "Walking past a live boss cannot complete the game."
	)
	_check(not game.level.gate_open, "The live boss keeps the gate locked.")
	await _test_boss_pause_and_retry()
	await _finish_boss_by_stomping()
	_check(game.level.gate_open, "Defeating Old Croak opens the final gate.")
	_check(not is_instance_valid(game.arena_wall), "Defeat removes the arena barrier.")
	await _test_defeated_boss_retry()
	game.fox.reset_at(game.level.gate)
	await _step(3)
	_check(game.state == Adventure.State.WON, "The cleared gate finishes the full campaign.")
	_check(not game.fox.active and not game.level.active, "Campaign victory freezes hazards.")
	_check(game.best_time > 0.0, "Campaign victory records its total finishing time.")
	var config := ConfigFile.new()
	_check(config.load(Adventure.SAVE_PATH) == OK, "Campaign victory writes its record.")
	_check(
		is_equal_approx(float(config.get_value("game", "campaign_best_time", 0.0)), game.best_time),
		"Campaign records use a separate key from the original one-level record."
	)
	var finish_time: float = game.elapsed
	await _step(5)
	_check(game.elapsed == finish_time, "The victory screen preserves the final time.")
	_press_button("Explore again")
	_check(
		game.state == Adventure.State.PLAYING and game.stage_index == 0,
		"Replay returns to chapter one."
	)
	_check(game.elapsed == 0.0 and game.deaths == 0, "Replay clears campaign time and retries.")
	_check(game.chapter_results.is_empty(), "Replay clears previous chapter results.")
	_check(
		game.level.taken_gems.is_empty() and game.level.taken_acorns.is_empty(),
		"Replay restores every collectible."
	)
	_check(not game.level.secret_found, "Replay restores the secret firefly.")
	_check(game.level.camp_index == 0, "Replay resets to the first campfire.")
	_check(game.fox.position == game.level.camps[0], "Replay starts at the forest entrance.")
	_check(not is_instance_valid(game.boss), "Replay frees the previous boss encounter.")


func _collect_acorns() -> void:
	for point: Vector2 in game.level.acorns:
		await _touch(point)
	_check(game.level.taken_acorns.size() == 3, "The chapter's three acorns collect by contact.")


func _test_boss_pause_and_retry() -> void:
	_press_button("Ⅱ")
	game._toggle_equipment(&"armor", false)
	_check(not game.fox.armor_equipped, "Armor can be removed to test ordinary boss damage.")
	var phase_time: float = game.boss.phase_time
	var boss_position: Vector2 = game.boss.position
	var wave_snapshot: Array = game.boss.waves.duplicate(true)
	await _step(45)
	_check(game.boss.phase_time == phase_time, "Pause freezes the boss attack countdown.")
	_check(game.boss.position == boss_position, "Pause freezes boss movement.")
	_check(game.boss.waves == wave_snapshot, "Pause freezes all boss ripples.")
	_press_button("Keep exploring")
	await _step(2)
	_check(game.boss.active and game.boss.phase_time > phase_time, "Resume continues the attack.")
	game.invincible_left = 0.0
	game.boss.player_hit.emit()
	_check(game.player_health == 2, "Boss contact removes one fox heart.")
	_check(
		game.hud._boss_count.text.ends_with("FOX  ●●○"),
		"The visible heart count updates on contact."
	)
	_check(game.invincible_left > 0.0, "A boss hit gives recovery time.")
	game.boss.player_hit.emit()
	_check(game.player_health == 2, "Immediate repeated contact cannot drain every heart.")
	game.invincible_left = 0.0
	game.boss.player_hit.emit()
	_check(game.player_health == 1, "A later hit removes the next heart.")
	game.invincible_left = 0.0
	game.boss.player_hit.emit()
	_check(
		game.hud._boss_count.text.ends_with("FOX  ○○○"),
		"The retry screen shows no remaining hearts."
	)
	_check(game.state == Adventure.State.RESPAWNING, "The third hit retries the fight.")
	_check(not game.boss.active, "Retry freezes the boss and its attacks.")
	var saved_acorns: Dictionary = game.level.taken_acorns.duplicate()
	await _step(55)
	_check(game.state == Adventure.State.PLAYING, "The boss retry returns to play.")
	_check(game.player_health == 3 and game.boss.health == 3, "Retry restores both combatants.")
	_check(game.boss.waves.is_empty(), "Retry removes the previous attack's ripples.")
	_check(game.level.taken_acorns == saved_acorns, "Boss retry preserves collected acorns.")
	_check(
		game.fox.position.distance_to(game.level.camps[-1]) < 1,
		"Boss retry uses the arena campfire."
	)
	_check(not game.level.gate_open, "Retry cannot accidentally unlock the boss gate.")


func _finish_boss_by_stomping() -> void:
	for hit in 3:
		# Lure the next leap into open ground, away from the arena refuge ledges.
		game.fox.reset_at(Vector2(3000, ForestLevel.FLOOR_Y))
		game.invincible_left = 5.0
		var found_opening := false
		for frame in 360:
			await _step(1)
			if game.boss.phase == "rest":
				found_opening = true
				break
		_check(found_opening, "The boss exposes a resting head after each attack.")
		if not found_opening:
			return
		game.invincible_left = 1.0
		game.fox.reset_at(game.boss.position - Vector2(0, 135))
		var previous_health: int = game.boss.health
		for frame in 60:
			await _step(1)
			if game.boss.health < previous_health:
				break
		_check(
			game.boss.health == previous_health - 1,
			"Real falling contact damages the open cap once."
		)
		_check(game.fox.velocity.y < 0, "A valid stomp bounces the fox back into the air.")
	_check(game.boss.defeated, "Three real stomp contacts defeat the boss.")


func _test_defeated_boss_retry() -> void:
	var retries: int = game.deaths
	_key(KEY_R, true)
	_key(KEY_R, false)
	await _step(2)
	_check(game.state == Adventure.State.RESPAWNING, "R still retries after defeating the boss.")
	await _step(55)
	_check(game.deaths == retries + 1, "The completed-fight retry is counted once.")
	_check(game.boss.defeated and game.boss.health == 0, "Retry preserves the defeated boss.")
	_check(game.level.gate_open, "Retry cannot relock an earned final gate.")
	_check(not game.boss.engaged, "Retry does not restart a completed encounter.")
	_check(not is_instance_valid(game.arena_wall), "Retry keeps the completed arena open.")
	_check(
		not game.hud._boss_band.visible, "A completed encounter keeps its health display hidden."
	)
	# Fall through the real gap just left of the now-open arena; do not call respawn.
	game.fox.reset_at(Vector2(2470, ForestLevel.FLOOR_Y))
	for frame in 120:
		await _step(1)
		if game.state == Adventure.State.RESPAWNING:
			break
	_check(
		game.state == Adventure.State.RESPAWNING, "Backtracking into the gap causes a real fall."
	)
	await _step(55)
	_check(game.deaths == retries + 2, "The post-victory fall counts as a retry.")
	_check(game.boss.defeated and game.boss.health == 0, "A fall also preserves boss completion.")
	_check(game.level.gate_open and not game.boss.engaged, "The path remains clear after the fall.")
	_check(not is_instance_valid(game.arena_wall), "The boss barrier stays removed after the fall.")
	_check(game.player_health == 3, "The checkpoint still restores the fox's hearts.")


func _test_settings_reload() -> void:
	_press_button("Ⅱ")
	var sound_button := _find_button(game.hud, "Sound") as CheckButton
	var motion_button := _find_button(game.hud, "Gentle motion") as CheckButton
	_check(sound_button != null and motion_button != null, "Pause exposes preference controls.")
	if sound_button == null or motion_button == null:
		return
	sound_button.button_pressed = false
	motion_button.button_pressed = true
	_check(game.sound.muted, "The sound switch mutes the actual sound controller.")
	_check(game.reduced_motion, "The motion switch enables gentle motion.")
	_check(
		game.level.reduced_motion and game.backdrop.reduced_motion,
		"Gentle motion reaches scenery and gameplay artwork."
	)
	_check(game.particles.is_empty(), "Gentle motion clears decorative particles.")
	var config := ConfigFile.new()
	_check(config.load(Adventure.SAVE_PATH) == OK, "The settings file is written successfully.")
	_check(config.get_value("settings", "muted", false), "The mute setting is saved.")
	_check(config.get_value("settings", "reduced_motion", false), "Gentle motion is saved.")
	var saved_best: float = game.best_time
	game.queue_free()
	await process_frame
	game = MAIN.instantiate()
	root.add_child(game)
	await _step(3)
	_check(game.state == Adventure.State.TITLE, "Reopening starts on the title screen.")
	_check(game.sound.muted and game.hud.muted, "Reopening loads and displays the mute preference.")
	_check(
		game.reduced_motion and game.hud.reduced_motion,
		"Reopening loads and displays the gentle-motion preference."
	)
	_check(
		is_equal_approx(game.best_time, saved_best),
		"Reopening retains best time: %.12f -> %.12f." % [saved_best, game.best_time]
	)
	_press_button("Start adventure")
	_check(game.level.taken_acorns.is_empty(), "A new session starts a fresh adventure.")
	_check(game.sound.muted and game.reduced_motion, "A new run keeps saved preferences.")


func _test_save_merging() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "campaign_best_time", 0.0)
	config.set_value("settings", "muted", false)
	config.set_value("settings", "reduced_motion", false)
	config.set_value("future_options", "keep_me", "unchanged")
	_check(config.save(Adventure.SAVE_PATH) == OK, "The two-window save fixture is written.")
	var older: Node2D = MAIN.instantiate()
	root.add_child(older)
	var newer: Node2D = MAIN.instantiate()
	root.add_child(newer)
	await _step(2)
	newer.best_time = 91.0
	newer._save_settings()
	newer._toggle_motion(true)
	older._toggle_sound(true)
	_check(config.load(Adventure.SAVE_PATH) == OK, "The shared save remains readable.")
	_check(
		config.get_value("game", "campaign_best_time") == 91.0,
		"An older window cannot erase a newer best time."
	)
	_check(older.best_time == 91.0, "Saving also refreshes the older window's best time.")
	_check(config.get_value("settings", "muted"), "The requested mute change is saved.")
	_check(
		config.get_value("settings", "reduced_motion"),
		"Changing sound preserves another window's motion choice."
	)
	older.best_time = 80.0
	older._save_settings()
	_check(config.load(Adventure.SAVE_PATH) == OK, "A new winning time is saved.")
	_check(
		config.get_value("game", "campaign_best_time") == 80.0,
		"A faster new record replaces the previous record."
	)
	_check(
		config.get_value("settings", "reduced_motion"),
		"Saving a win cannot overwrite stale preferences."
	)
	newer._toggle_motion(false)
	_check(config.load(Adventure.SAVE_PATH) == OK, "The second preference change is saved.")
	_check(
		config.get_value("game", "campaign_best_time") == 80.0,
		"A stale slower record cannot replace a faster one."
	)
	_check(
		config.get_value("settings", "muted"),
		"Changing motion preserves another window's mute choice."
	)
	_check(
		not config.get_value("settings", "reduced_motion"), "The requested motion change is saved."
	)
	_check(
		config.get_value("future_options", "keep_me") == "unchanged",
		"Saving preserves unfamiliar configuration keys."
	)
	older.queue_free()
	newer.queue_free()
	await process_frame
	await _test_save_creation_and_failure()


func _test_save_creation_and_failure() -> void:
	var save_path := ProjectSettings.globalize_path(Adventure.SAVE_PATH)
	_check(DirAccess.remove_absolute(save_path) == OK, "The isolated save fixture can be reset.")
	game.sound.muted = true
	game.reduced_motion = true
	game._save_settings()
	var valid_config := ConfigFile.new()
	_check(valid_config.load(Adventure.SAVE_PATH) == OK, "A first save creates valid settings.")
	_check(
		valid_config.get_value("settings", "muted"),
		"A first save initializes current sound preferences."
	)
	_check(
		valid_config.get_value("settings", "reduced_motion"),
		"A first save initializes current motion preferences."
	)
	var invalid_contents := "[settings\nmuted=true\n"
	var invalid_file := FileAccess.open(Adventure.SAVE_PATH, FileAccess.WRITE)
	invalid_file.store_string(invalid_contents)
	invalid_file.close()
	# A deliberately malformed fixture must be rejected without noisy parser diagnostics.
	var errors_enabled := Engine.print_error_messages
	Engine.print_error_messages = false
	_key(KEY_M, true)
	_key(KEY_M, false)
	await process_frame
	Engine.print_error_messages = errors_enabled
	_check(not game.sound.muted, "M still changes sound when its preference cannot be saved.")
	_check(
		FileAccess.get_file_as_string(Adventure.SAVE_PATH) == invalid_contents,
		"An unreadable save is never overwritten by a preference toggle."
	)
	_check(
		game.hud._toast_label.text.contains("existing save was left unchanged"),
		"The M key's sound feedback does not hide the save failure message."
	)
	_check(
		valid_config.save(Adventure.SAVE_PATH) == OK, "The test restores its valid isolated save."
	)


func _touch(point: Vector2) -> void:
	game.fox.reset_at(point + Vector2(0.0, 18.0))
	await _step(3)


func _platform_of_kind(kind: String) -> ForestPlatform:
	for platform: ForestPlatform in game.level.platforms:
		if platform.kind == kind:
			return platform
	return null


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _press_button(prefix: String) -> void:
	var button := _find_button(game.hud, prefix)
	_check(button != null, "The interface contains the '%s' button." % prefix)
	if button != null:
		button.pressed.emit()


func _find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix) and node.is_visible_in_tree():
		return node
	for child: Node in node.get_children():
		var found := _find_button(child, prefix)
		if found != null:
			return found
	return null


func _step(frames: int) -> void:
	for frame: int in range(frames):
		await physics_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
