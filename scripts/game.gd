extends Node2D
## Owns the adventure state. Level and fox keep their own rendering/physics.

enum State { TITLE, PLAYING, PAUSED, RESPAWNING, WON, CHAPTER_COMPLETE }

const SAVE_PATH := "user://emberwood.cfg"
const VIEW_WIDTH := 1152.0
const PARTY_SPACING := 50.0
const CHAPTER_TITLES := ForestChapters.TITLES

var state := State.TITLE
var state_before_pause := State.PLAYING
var stage_index := 0
var chapter_started_at := 0.0
var chapter_results: Array[Dictionary] = []
var boss: ForestBoss
var boss_started := false
var player_health := 3
var arena_wall: ForestPlatform
var level: ForestLevel
var fox: ForestFox
var backdrop: ForestBackdrop
var hud: ForestHUD
var sound: ForestSound
var camera: Camera2D
var elapsed := 0.0
var deaths := 0
var best_time := 0.0
var respawn_left := 0.0
var invincible_left := 0.0
var mushroom_cooldown: float:
	get:
		return fox.mushroom_cooldown if is_instance_valid(fox) else 0.0
	set(value):
		if is_instance_valid(fox):
			fox.mushroom_cooldown = value
var gate_hint_cooldown := 0.0
var camera_x := 0.0
var particles: Array[Dictionary] = []
var reduced_motion := false
var last_zone := ""
var equipment := ForestEquipment.new()
var arrows: Node2D
var shot_cooldown: float:
	get:
		return fox.weapon_cooldown if is_instance_valid(fox) else 0.0
	set(value):
		if is_instance_valid(fox):
			fox.weapon_cooldown = value
var lan: ForestLAN
var party: Array[ForestFox] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop = ForestBackdrop.new()
	add_child(backdrop)
	fox = ForestFox.new()
	fox.z_index = 10
	add_child(fox)
	party.append(fox)
	fox.jumped.connect(_on_jump)
	fox.dashed.connect(func() -> void: sound.play("dash"))
	fox.shot_requested.connect(_shoot)
	camera = Camera2D.new()
	camera.position = Vector2(VIEW_WIDTH / 2, 324)
	add_child(camera)
	sound = ForestSound.new()
	add_child(sound)
	hud = ForestHUD.new()
	add_child(hud)
	lan = ForestLAN.new()
	lan.name = "LAN"
	add_child(lan)
	lan.setup(self)
	hud.start_requested.connect(start_run)
	hud.next_requested.connect(next_chapter)
	hud.restart_requested.connect(start_run)
	hud.resume_requested.connect(resume_run)
	hud.pause_requested.connect(pause_run)
	hud.sound_toggled.connect(_toggle_sound)
	hud.motion_toggled.connect(_toggle_motion)
	hud.equipment_toggled.connect(_toggle_equipment)
	_load_chapter(0)
	_load_settings()
	hud.show_title(best_time)
	_refresh_hud()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("pause"):
		if state in [State.PLAYING, State.RESPAWNING]:
			pause_run()
		elif state == State.PAUSED:
			resume_run()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("retry") and state == State.PLAYING:
		if not lan.request_action("retry"):
			_respawn("Back to your campfire")
	elif event.is_action_pressed("mute"):
		hud.toast("Sound off" if not sound.muted else "Sound on", false)
		_toggle_sound(not sound.muted)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state in [State.PLAYING, State.RESPAWNING]:
		pause_run()


func start_run() -> void:
	if lan.is_guest():
		return
	chapter_results.clear()
	equipment.reset()
	elapsed = 0.0
	deaths = 0
	_load_chapter(0)
	_set_state(State.PLAYING)
	hud.hide_overlay()
	hud.toast("Find three acorns to leave the forest. Campfires mark your return point.")
	sound.stop()
	_refresh_hud()


func _load_chapter(index: int) -> void:
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	boss = null
	arena_wall = null
	boss_started = false
	player_health = 3
	stage_index = index
	chapter_started_at = elapsed
	level = ForestLevel.new()
	level.stage_index = index
	add_child(level)
	arrows = Node2D.new()
	arrows.z_index = 12
	level.add_child(arrows)
	shot_cooldown = 0.0
	if ForestChapters.has_boss(index):
		boss = ForestBoss.new()
		boss.configure(index)
		boss.fox = fox
		boss.party = party
		level.add_child(boss)
		boss.player_hit.connect(_on_boss_hit)
		boss.damaged.connect(_on_boss_damaged)
		boss.defeated_boss.connect(_on_boss_defeated)
		level.gate_open = false
	level.reduced_motion = reduced_motion
	backdrop.chapter_index = index
	backdrop.reduced_motion = reduced_motion
	if is_instance_valid(boss):
		boss.reduced_motion = reduced_motion
	invincible_left = 0.8
	mushroom_cooldown = 0.0
	gate_hint_cooldown = 0.0
	particles.clear()
	_reset_party(level.camps[0])
	_sync_equipment()
	camera_x = 0.0
	last_zone = ""
	hud.set_chapter(index, CHAPTER_TITLES[index], level.required_acorns)
	hud.update_boss(false, 3, player_health, "")


func next_chapter() -> void:
	if lan.is_guest():
		return
	if state != State.CHAPTER_COMPLETE or stage_index >= CHAPTER_TITLES.size() - 1:
		return
	_load_chapter(stage_index + 1)
	_set_state(State.PLAYING)
	hud.hide_overlay()
	hud.toast("%s — find three acorns and the next trail marker." % level.title)
	_refresh_hud()


func _complete_chapter() -> void:
	_set_state(State.CHAPTER_COMPLETE)
	for member in party:
		member.show_pose(&"victory")
		member.velocity = Vector2.ZERO
	chapter_results.append(
		{"gems": level.taken_gems.size(), "total": level.gems.size(), "secret": level.secret_found}
	)
	sound.play("acorn")
	hud.show_stage_complete(
		level.title,
		CHAPTER_TITLES[stage_index + 1],
		format_time(elapsed - chapter_started_at),
		level.taken_gems.size(),
		level.gems.size()
	)


func pause_run() -> void:
	if lan.request_action("pause"):
		return
	if state not in [State.PLAYING, State.RESPAWNING]:
		return
	state_before_pause = state
	_set_state(State.PAUSED)
	sound.stop()
	hud.show_pause()


func resume_run() -> void:
	if lan.request_action("resume"):
		return
	if state != State.PAUSED:
		return
	_set_state(state_before_pause)
	hud.hide_overlay()


func _set_state(next: State) -> void:
	state = next
	for member in party:
		member.active = state == State.PLAYING
		member.set_physics_process(not lan.is_guest())
		member.sprite.speed_scale = 0.0 if state == State.PAUSED else 1.0
		if state != State.PLAYING:
			member.clear_network_input()
	level.set_active(state == State.PLAYING and not lan.is_guest())
	if is_instance_valid(boss):
		boss.active = state == State.PLAYING and not lan.is_guest()
	backdrop.set_process(state != State.PAUSED)
	for arrow in arrows.get_children():
		arrow.active = state == State.PLAYING and not lan.is_guest()


func _physics_process(delta: float) -> void:
	if lan.is_guest():
		return
	if state == State.RESPAWNING:
		respawn_left -= delta
		if respawn_left <= 0:
			_finish_respawn()
	if state != State.PLAYING:
		return
	elapsed += delta
	invincible_left = maxf(0, invincible_left - delta)
	gate_hint_cooldown = maxf(0, gate_hint_cooldown - delta)
	for member in party:
		member.modulate.a = 1.0
		if invincible_left > 0:
			member.modulate.a = (
				0.75 if reduced_motion else (0.65 if int(invincible_left * 10) % 2 else 1.0)
			)
		_check_hazards(member)
		if state != State.PLAYING:
			return
		_check_pickups(member)
		_check_platforms(member)
		_update_boss_encounter(member)
		_check_camps_and_gate(member)
		if state != State.PLAYING:
			break
	_refresh_hud()


func _process(delta: float) -> void:
	if state in [State.PLAYING, State.RESPAWNING, State.WON]:
		var target := clampf(local_fox().position.x - 380, 0, level.world_width - VIEW_WIDTH)
		camera_x = target if reduced_motion else lerpf(camera_x, target, 1.0 - exp(-8 * delta))
	camera.position.x = roundf(camera_x) + VIEW_WIDTH / 2
	backdrop.view_x = roundf(camera_x)
	level.camera_x = camera_x
	if state != State.PAUSED:
		for particle in particles:
			particle.life -= delta
			particle.pos += particle.vel * delta
			particle.vel.y += 220 * delta
		particles = particles.filter(func(p: Dictionary) -> bool: return p.life > 0)
	queue_redraw()


func _check_hazards(member: ForestFox = null) -> void:
	var actor := fox if member == null else member
	if actor.position.y > 730:
		_respawn("A little tumble. Try that jump again!")
		return
	var bounds := actor.body_bounds()
	for spike in level.spikes:
		# Inset the rectangular artwork so brushing a triangle's corner is forgiving.
		if invincible_left <= 0 and bounds.intersects(spike.grow(-3)):
			if _absorb_hit():
				return
			_respawn("Ouch! Jump over the spikes.")
			return
	for critter in level.critters:
		if critter.out:
			continue
		var pos := level.critter_position(critter)
		var target := level.critter_bounds(critter)
		if bounds.intersects(target):
			if actor.velocity.y > 40 and actor.position.y < target.get_center().y:
				critter.out = true
				actor.bounce(-440)
				_burst(pos - Vector2(0, 20), Color("d7b2df"), 12)
				sound.play("bounce")
			elif invincible_left <= 0:
				if _absorb_hit():
					return
				_respawn("Boop! Hop over critters, or bounce on top.")
				return


func _check_pickups(member: ForestFox = null) -> void:
	var actor := fox if member == null else member
	var bounds := actor.body_bounds().grow(9)
	for index in level.gems.size():
		if not level.taken_gems.has(index) and bounds.has_point(level.gems[index]):
			level.taken_gems[index] = true
			_burst(level.gems[index], Color("b1f0dc"), 9)
			sound.play("gem")
	for index in level.acorns.size():
		if not level.taken_acorns.has(index) and bounds.grow(5).has_point(level.acorns[index]):
			level.taken_acorns[index] = true
			_burst(level.acorns[index], Color("ffcf88"), 24)
			sound.play("acorn")
			var found := level.taken_acorns.size()
			hud.toast(
				(
					"Magic acorn %d / 3!" % found
					if found < 3
					else "All three acorns collected. Follow the trail to the gate."
				)
			)
	if not level.secret_found and bounds.has_point(level.secret):
		level.secret_found = true
		_burst(level.secret, Color("ffeda3"), 28)
		sound.play("acorn")
		hud.toast("A hidden firefly! You found the forest's little secret.")


func _check_platforms(member: ForestFox = null) -> void:
	var actor := fox if member == null else member
	if actor.is_on_floor():
		for index in actor.get_slide_collision_count():
			var collision := actor.get_slide_collision(index)
			var body := collision.get_collider()
			if body is ForestPlatform and collision.get_normal().y < -0.7:
				body.step_on()
	for mushroom in level.mushrooms:
		if actor.mushroom_cooldown <= 0 and actor.velocity.y >= 0:
			if absf(actor.position.x - mushroom.x) < 32 and actor.position.y > mushroom.y - 28:
				actor.bounce(-770)
				actor.mushroom_cooldown = 0.3
				_burst(mushroom - Vector2(0, 25), Color("f8b5d5"), 18)
				sound.play("bounce")


func _check_camps_and_gate(member: ForestFox = null) -> void:
	var actor := fox if member == null else member
	for index in level.camps.size():
		if index > level.camp_index and actor.position.distance_to(level.camps[index]) < 50:
			_activate_camp(index)
	if absf(actor.position.x - level.gate.x) < 42 and actor.position.y > 410:
		if level.taken_acorns.size() == level.acorns.size() and level.gate_open:
			if stage_index < CHAPTER_TITLES.size() - 1:
				_complete_chapter()
			else:
				_win()
		elif gate_hint_cooldown <= 0:
			gate_hint_cooldown = 4.0
			var missing := 0
			while missing < level.acorns.size() and level.taken_acorns.has(missing):
				missing += 1
			if missing == level.acorns.size():
				hud.toast(
					"%s guards this gate. Attack the gold cap during rest." % boss.guardian_name
				)
			else:
				hud.toast("Acorn %d is still on the trail to the left." % (missing + 1))


func _respawn(message: String) -> void:
	if state != State.PLAYING:
		return
	deaths += 1
	_set_state(State.RESPAWNING)
	_clear_arrows()
	respawn_left = 0.8
	for member in party:
		member.show_pose(&"hurt")
	_burst(fox.position - Vector2(0, 24), Color("f2b694"), 15)
	sound.play("hurt")
	hud.toast(message)


func _finish_respawn() -> void:
	level.reset_hazards()
	if is_instance_valid(boss):
		player_health = 3
		# A finished encounter is earned progress, like collected acorns.
		if not boss.defeated:
			boss.reset_battle()
			boss_started = false
		level.gate_open = boss.defeated
		set_arena_wall(false)
	_reset_party(level.camps[level.camp_index])
	equipment.recharge()
	_sync_equipment()
	shot_cooldown = 0.0
	invincible_left = 1.0
	mushroom_cooldown = 0.0
	camera_x = clampf(local_fox().position.x - 380, 0, level.world_width - VIEW_WIDTH)
	_set_state(State.PLAYING)


func _win() -> void:
	_set_state(State.WON)
	for member in party:
		member.show_pose(&"victory")
		member.velocity = Vector2.ZERO
	if not lan.connected and (best_time <= 0 or elapsed < best_time):
		best_time = elapsed
		_save_settings()
	sound.play("win")
	_burst(fox.position - Vector2(0, 60), Color("ffdda1"), 70)
	show_campaign_results()


func show_campaign_results() -> void:
	var found := level.taken_gems.size()
	var total := level.gems.size()
	var all_secrets := level.secret_found
	for result in chapter_results:
		found += int(result.gems)
		total += int(result.total)
		all_secrets = all_secrets and bool(result.secret)
	hud.show_win(format_time(elapsed), found, total, deaths, all_secrets, CHAPTER_TITLES.size())


func _on_jump(double_jump: bool) -> void:
	sound.play("double" if double_jump else "jump")
	_burst(fox.position, Color("bdd7c3"), 7 if double_jump else 4)


func _burst(pos: Vector2, color: Color, count: int) -> void:
	if reduced_motion:
		return
	for n in count:
		particles.append(
			{
				"pos": pos,
				"vel": Vector2(randf_range(-110, 110), randf_range(-150, -30)),
				"life": randf_range(0.3, 0.8),
				"color": color
			}
		)


func _draw() -> void:
	if is_instance_valid(arena_wall):
		var wall_x := boss.arena_min - 100
		for offset in [0, 8, 16]:
			draw_line(
				Vector2(wall_x + offset, 536), Vector2(wall_x + offset, 250), Color("6a7653"), 5
			)
			for y in range(270, 530, 38):
				draw_line(
					Vector2(wall_x + offset, y),
					Vector2(wall_x - 16 + offset, y - 18),
					Color("a4b979"),
					5
				)
	for particle in particles:
		var color: Color = particle.color
		color.a = minf(1.0, particle.life * 2)
		draw_rect(Rect2(particle.pos, Vector2(4, 4)), color)


func _refresh_hud() -> void:
	var actor := local_fox()
	var zone := level.zone_title(actor.position.x)
	last_zone = zone
	hud.update_stats(
		level.taken_acorns.size(),
		level.taken_gems.size(),
		level.gems.size(),
		format_time(elapsed),
		zone,
		actor.jumps_left
	)
	hud.update_equipment(equipment, local_fox().can_dash())


func format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _toggle_sound(value: bool) -> void:
	sound.muted = value
	hud.muted = value
	if value:
		sound.stop()
	_save_settings(&"muted")


func _toggle_motion(value: bool) -> void:
	reduced_motion = value
	hud.reduced_motion = value
	backdrop.reduced_motion = value
	level.reduced_motion = value
	for member in party:
		member.reduced_motion = value
	if is_instance_valid(boss):
		boss.reduced_motion = value
	if value:
		particles.clear()
	_save_settings(&"reduced_motion")


func _read_settings(config: ConfigFile) -> Error:
	var error := config.load(SAVE_PATH)
	if error != ERR_FILE_NOT_FOUND:
		return error
	# The ASCII window title changes Godot's default data-directory name.
	# Read older preferences until the first normal save creates the new file.
	var previous := OS.get_user_data_dir().get_base_dir().path_join(
		"Emberwood — Forest Adventure/emberwood.cfg"
	)
	return config.load(previous)


func _load_settings() -> void:
	var config := ConfigFile.new()
	var error := _read_settings(config)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_warning("Could not read Emberwood settings; using defaults.")
		return
	var saved_best := float(config.get_value("game", ForestChapters.CAMPAIGN_BEST_KEY, 0.0))
	best_time = saved_best if is_finite(saved_best) and saved_best > 0.0 else 0.0
	sound.muted = bool(config.get_value("settings", "muted", false))
	hud.muted = sound.muted
	reduced_motion = bool(config.get_value("settings", "reduced_motion", false))
	hud.reduced_motion = reduced_motion
	backdrop.reduced_motion = reduced_motion
	level.reduced_motion = reduced_motion
	fox.reduced_motion = reduced_motion
	if is_instance_valid(boss):
		boss.reduced_motion = reduced_motion


func _save_settings(changed_setting: StringName = &"") -> void:
	var config := ConfigFile.new()
	var error := _read_settings(config)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		hud.toast("Couldn't read saved settings. Your existing save was left unchanged.")
		return
	# Another open window may have earned a faster time or changed another setting.
	var saved_best := float(config.get_value("game", ForestChapters.CAMPAIGN_BEST_KEY, 0.0))
	if is_finite(saved_best) and saved_best > 0.0:
		if best_time <= 0.0 or saved_best < best_time:
			best_time = saved_best
	config.set_value("game", ForestChapters.CAMPAIGN_BEST_KEY, best_time)
	if changed_setting == &"muted" or not config.has_section_key("settings", "muted"):
		config.set_value("settings", "muted", sound.muted)
	if (
		changed_setting == &"reduced_motion"
		or not config.has_section_key("settings", "reduced_motion")
	):
		config.set_value("settings", "reduced_motion", reduced_motion)
	if config.save(SAVE_PATH) != OK:
		hud.toast("Couldn't save settings. You can still keep playing.")


func _update_boss_encounter(member: ForestFox = null) -> void:
	var actor := fox if member == null else member
	if not is_instance_valid(boss):
		return
	if (
		not boss_started
		and not boss.defeated
		and actor.position.x >= boss.arena_min + 30
		and level.taken_acorns.size() == level.required_acorns
	):
		boss_started = true
		player_health = 3
		_activate_camp(level.camps.size() - 1)
		set_arena_wall(true)
		for friend in party:
			if friend.position.x < boss.arena_min:
				friend.reset_at(
					Vector2(boss.arena_min + 40 + party.find(friend) * PARTY_SPACING, 536)
				)
		boss.begin()
		sound.play("camp")
		hud.toast("%s: dodge the landing mark, then attack the gold cap." % boss.guardian_name)
	hud.update_boss(
		boss_started and not boss.defeated,
		boss.health,
		player_health,
		boss.status_text(),
		boss.guardian_name
	)


func _on_boss_hit() -> void:
	if state != State.PLAYING or invincible_left > 0:
		return
	if _absorb_hit():
		return
	player_health -= 1
	hud.update_boss(true, boss.health, player_health, boss.status_text(), boss.guardian_name)
	if player_health <= 0:
		_respawn("Back to the arena campfire. Watch the landing mark before you jump.")
		return
	invincible_left = 1.3
	_burst(fox.position - Vector2(0, 24), Color("dcaa82"), 10)
	sound.play("hurt")
	hud.toast("%d hearts left. His head is safe to land on while he rests." % player_health)


func _on_boss_damaged(_remaining: int) -> void:
	hud.update_boss(true, boss.health, player_health, boss.status_text(), boss.guardian_name)
	sound.play("acorn")
	_burst(boss.position - Vector2(0, 70), Color("d7c277"), 20)


func _on_boss_defeated() -> void:
	level.gate_open = true
	set_arena_wall(false)
	sound.play("win")
	hud.toast("%s yields the path. The gate is just ahead." % boss.guardian_name)
	hud.update_boss(false, 0, player_health, "")


func _activate_camp(index: int) -> void:
	if index <= level.camp_index:
		return
	level.camp_index = index
	var rewards := equipment.rewards_at(stage_index, index)
	equipment.recharge()
	_sync_equipment()
	sound.play("camp")
	_burst(level.camps[index] - Vector2(0, 25), Color("ffc887"), 20)
	if not rewards.is_empty():
		var names := PackedStringArray()
		for item_id in rewards:
			names.append(ForestEquipment.definition(item_id).name)
		hud.toast("New gear: %s. J uses your weapon; Esc chooses equipment." % ", ".join(names))
	else:
		hud.toast(
			(
				"Campfire lit! Armor recharged."
				if equipment.is_unlocked(&"armor")
				else "Campfire lit! Your treasure is safe."
			)
		)


func _toggle_equipment(item_id: StringName, enabled: bool) -> void:
	if lan.is_guest():
		return
	if state != State.PAUSED or not equipment.set_equipped(item_id, enabled):
		return
	_sync_equipment()


func _sync_equipment() -> void:
	for member in party:
		member.bow_equipped = equipment.is_equipped(&"bow")
		member.armor_equipped = equipment.active_armor() != &""
		member.weapon_id = equipment.active_weapon()
		member.armor_id = equipment.active_armor()
		member.armor_charged = equipment.armor_charge > 0
		member.queue_redraw()
	hud.update_equipment(equipment, local_fox().can_dash())


func _absorb_hit() -> bool:
	if not equipment.absorb_hit():
		return false
	invincible_left = 1.3
	_sync_equipment()
	sound.play("armor")
	_burst(fox.position - Vector2(0, 24), Color("c7dcac"), 12)
	var armor_name: String = ForestEquipment.definition(equipment.active_armor()).name
	hud.toast("%s blocked the hit. Blocks left: %d." % [armor_name, equipment.armor_charge])
	return true


func _shoot(member: ForestFox = null) -> void:
	var actor := fox if member == null else member
	var weapon := equipment.active_weapon()
	if state != State.PLAYING or weapon == &"" or actor.weapon_cooldown > 0:
		return
	var stats := ForestEquipment.definition(weapon)
	actor.weapon_cooldown = float(stats.cooldown)
	for angle: float in stats.get("angles", [0.0]):
		var arrow := ForestArrow.new()
		# Each shot starts inside the actor so a thin wall cannot be skipped.
		arrow.setup(
			actor.position + Vector2(0, -20), actor.facing, level, boss, actor, weapon, angle
		)
		arrow.struck.connect(_on_arrow_struck)
		arrows.add_child(arrow)
	sound.play("shoot" if weapon == &"bow" else String(weapon))


func _on_arrow_struck(point: Vector2, target: String) -> void:
	_burst(point, Color("bdcda2") if target == "blocked" else Color("d7b2df"), 5)
	if target == "critter":
		sound.play("bounce")


func _clear_arrows() -> void:
	for arrow in arrows.get_children():
		arrows.remove_child(arrow)
		arrow.queue_free()


func local_fox() -> ForestFox:
	return lan.local_fox() if is_instance_valid(lan) else fox


func _reset_party(at: Vector2) -> void:
	for index in party.size():
		party[index].reset_at(at + Vector2(index * PARTY_SPACING, 0))


func add_party_member() -> ForestFox:
	var member := ForestFox.new()
	member.z_index = 10
	member.network_controlled = true
	member.reduced_motion = reduced_motion
	add_child(member)
	party.append(member)
	member.jumped.connect(
		func(double: bool) -> void:
			sound.play("double" if double else "jump")
			_burst(member.position, Color("bdd7c3"), 7 if double else 4)
	)
	member.dashed.connect(func() -> void: sound.play("dash"))
	member.shot_requested.connect(_shoot.bind(member))
	member.reset_at(level.camps[level.camp_index] + Vector2((party.size() - 1) * PARTY_SPACING, 0))
	return member


func return_to_title(message: String = "") -> void:
	_set_state(State.TITLE)
	chapter_results.clear()
	equipment.reset()
	elapsed = 0.0
	deaths = 0
	_load_chapter(0)
	_refresh_hud()
	hud.show_title(best_time)
	if not message.is_empty():
		hud.toast(message)


func set_arena_wall(present: bool) -> void:
	if present and is_instance_valid(boss) and not is_instance_valid(arena_wall):
		arena_wall = ForestPlatform.new()
		arena_wall.setup(Rect2(boss.arena_min - 100, 250, 18, 286), "wall")
		level.add_child(arena_wall)
	elif not present and is_instance_valid(arena_wall):
		arena_wall.queue_free()
		arena_wall = null
