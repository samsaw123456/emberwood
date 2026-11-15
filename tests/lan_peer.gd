extends SceneTree
## Isolated native/network test fixture. Never included in release exports.

var game: Node2D
var directory := OS.get_environment("EMBERWOOD_TEST_DATA_DIR")
var peer_name := OS.get_environment("EMBERWOOD_TEST_PEER")
var command_id := 0
var frames := 0
var input_events: Array[String] = []
var jump_events: Array[Dictionary] = []


func _initialize() -> void:
	if directory.is_empty() or OS.get_environment("XDG_DATA_HOME") != directory:
		quit(2)
		return
	call_deferred(&"_start")


func _start() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	root.title = "Emberwood audit " + peer_name
	root.window_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventKey:
				input_events.append(
					(
						"%d %s %s echo:%s"
						% [Time.get_ticks_msec(), event.as_text(), event.pressed, event.echo]
					)
				)
				if input_events.size() > 30:
					input_events.pop_front()
	)
	game.fox.jumped.connect(
		func(double: bool) -> void:
			jump_events.append(
				{
					"time": Time.get_ticks_msec(),
					"double": double,
					"x": game.fox.position.x,
					"y": game.fox.position.y
				}
			)
			if jump_events.size() > 10:
				jump_events.pop_front()
	)


func _process(_delta: float) -> bool:
	if not is_instance_valid(game) or not game.is_node_ready():
		return false
	frames += 1
	var command_path := directory.path_join(peer_name + "-command.json")
	if FileAccess.file_exists(command_path):
		var command: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(command_path))
		if int(command.id) > command_id:
			_run_command(command)
			command_id = int(command.id)
	var players := []
	for member in game.party:
		players.append(
			{
				"number": member.player_number,
				"x": member.position.x,
				"y": member.position.y,
				"vx": member.velocity.x,
				"vy": member.velocity.y,
				"jumps": member.jumps_left,
				"active": member.active,
				"alpha": member.modulate.a,
				"mask": member.input_mask,
				"animation": member.sprite.animation
			}
		)
	var buttons := []
	for button in game.hud.find_children("*", "BaseButton", true, false):
		if button.is_visible_in_tree():
			var rect: Rect2 = button.get_global_rect()
			buttons.append(
				{
					"text": button.text,
					"disabled": button.disabled,
					"x": rect.get_center().x,
					"y": rect.get_center().y,
					"pressed": button.button_pressed
				}
			)
	var fields := []
	for field in game.hud.find_children("*", "LineEdit", true, false):
		if field.is_visible_in_tree():
			fields.append(
				{
					"text": field.text,
					"x": field.get_global_rect().get_center().x,
					"y": field.get_global_rect().get_center().y
				}
			)
	var status := {
		"events": input_events,
		"jump_events": jump_events,
		"command": command_id,
		"frames": frames,
		"focus": str(root.gui_get_focus_owner().name) if root.gui_get_focus_owner() else "",
		"focus_text":
		root.gui_get_focus_owner().text if root.gui_get_focus_owner() is BaseButton else "",
		"boss_phase": game.boss.phase if is_instance_valid(game.boss) else "",
		"boss_x": game.boss.position.x if is_instance_valid(game.boss) else 0.0,
		"boss_defeated": game.boss.defeated if is_instance_valid(game.boss) else false,
		"state": game.state,
		"stage": game.stage_index,
		"elapsed": game.elapsed,
		"deaths": game.deaths,
		"players": players,
		"connected": game.lan.connected,
		"connecting": game.lan.connecting,
		"lobby": game.lan.in_lobby,
		"hosting": game.lan.hosting,
		"local_number": game.local_fox().player_number,
		"local_x": game.local_fox().position.x,
		"local_y": game.local_fox().position.y,
		"camera": game.camera_x,
		"acorns": game.level.taken_acorns.size(),
		"gems": game.level.taken_gems.size(),
		"camp": game.level.camp_index,
		"weapon": game.equipment.active_weapon(),
		"armor": game.equipment.active_armor(),
		"charge": game.equipment.armor_charge,
		"arrows": game.arrows.get_child_count(),
		"boss_health": game.boss.health if is_instance_valid(game.boss) else -1,
		"muted": game.sound.muted,
		"motion": game.reduced_motion,
		"toast": game.hud._toast_label.text,
		"error": game.hud._lan_error.text if is_instance_valid(game.hud._lan_error) else "",
		"buttons": buttons,
		"fields": fields,
		"width": root.size.x,
		"height": root.size.y
	}
	var temporary := directory.path_join(peer_name + "-status.tmp")
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	file.store_string(JSON.stringify(status))
	file.close()
	DirAccess.rename_absolute(temporary, directory.path_join(peer_name + "-status.json"))
	return false


func _run_command(command: Dictionary) -> void:
	match command.op:
		"host":
			game.lan.set_physics_process(true)
			game.lan.host()
		"join":
			game.lan.set_physics_process(true)
			game.lan.join(command.get("address", "127.0.0.1"))
		"begin":
			game.lan.begin()
		"leave":
			game.lan.leave()
		"solo":
			game.start_run()
		"pause":
			game.pause_run()
		"resume":
			game.resume_run()
		"next":
			game.next_chapter()
		"restart":
			game.start_run()
		"retry":
			if not game.lan.request_action("retry"):
				game._respawn("Test retry")
		"input":
			game.lan.set_physics_process(false)
			game.lan._controls.rpc_id(1, int(command.mask))
		"key":
			var event := InputEventKey.new()
			event.physical_keycode = int(command.code)
			event.pressed = bool(command.pressed)
			Input.parse_input_event(event)
		"motion":
			game._toggle_motion(bool(command.enabled))
		"camp":
			game._activate_camp(int(command.index))
		"position":
			var member: ForestFox = game.party[int(command.get("player", 0))]
			member.reset_at(Vector2(command.x, command.y))
		"gear":
			game._toggle_equipment(command.item, command.enabled)
		"level":
			game._load_chapter(int(command.index))
			game._set_state(game.State.PLAYING)
			game.hud.hide_overlay()
		"gate":
			for index in game.level.acorns.size():
				game.level.taken_acorns[index] = true
			if is_instance_valid(game.boss):
				game.boss.defeated = true
			game.level.gate_open = true
			game.party[int(command.get("player", 0))].reset_at(game.level.gate)
		"pickup":
			game.party[int(command.player)].reset_at(
				game.level.acorns[int(command.index)] + Vector2(0, 16)
			)
		"boss_rest":
			game.boss.phase = "rest"
			game.boss.phase_time = 0.0
		"hold_connection":
			game.lan._connection_left = 30.0
		"hold_respawn":
			game.respawn_left = 30.0
		"finish_respawn":
			game.respawn_left = 0.0
		"arena":
			game.equipment.rewards_at(19, 1)
			game._load_chapter(2)
			game.equipment.set_equipped(&"bow", true)
			game._sync_equipment()
			for index in game.level.acorns.size():
				game.level.taken_acorns[index] = true
			for index in game.party.size():
				game.party[index].reset_at(Vector2(2645 + index * 35, 536))
			game._set_state(game.State.PLAYING)
			game.hud.hide_overlay()
		"render_off":
			RenderingServer.render_loop_enabled = false
		"render_on":
			RenderingServer.render_loop_enabled = true
		"quit":
			quit()
