class_name ForestLAN
extends Node
## Host-authoritative LAN session. Only fixed controls cross from guests to host.

const PORT := 24642
const PROTOCOL := 1
const MAX_PLAYERS := 4
const SNAPSHOT_INTERVAL := 1.0 / 30.0
const PACKET_BYTES := 1000
const GAME_FIELDS := [
	"state",
	"state_before_pause",
	"elapsed",
	"deaths",
	"player_health",
	"boss_started",
	"respawn_left",
	"invincible_left",
	"chapter_started_at",
	"chapter_results"
]
const LEVEL_FIELDS := [
	"age", "taken_gems", "taken_acorns", "secret_found", "camp_index", "gate_open", "critters"
]
const FOX_FIELDS := [
	"position",
	"velocity",
	"facing",
	"jumps_left",
	"dash_left",
	"dash_cooldown_left",
	"_air_dash_available",
	"_dash_direction",
	"modulate"
]
const BOSS_FIELDS := [
	"position",
	"health",
	"phase",
	"phase_time",
	"engaged",
	"defeated",
	"landing_x",
	"waves",
	"_animation_time",
	"_facing_left"
]
const ARROW_FIELDS := [
	"position", "_velocity", "_direction", "_spent", "_burst_left", "_age", "traveled"
]
const EQUIPMENT_FIELDS := ["unlocked", "equipped", "_last_armor", "_armor_damage"]

var game: Node2D
var connected := false
var hosting := false
var in_lobby := false
var connecting := false
var members: Dictionary = {}
var roster: Dictionary = {}
var peer: ENetMultiplayerPeer
var _last_input: Dictionary = {}
var _snapshot_left := 0.0
var _snapshot_id := 0
var _incoming_id := -1
var _incoming_parts: Dictionary = {}
var _heartbeat := 0.0
var _connection_left := 0.0
var _previous_mask := -1
var _blocked_mask := 0
var _remote_arrows: Dictionary = {}
var _last_snapshot := 0.0
var _command_times: Dictionary = {}


func setup(adventure: Node2D) -> void:
	game = adventure
	process_physics_priority = 100
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.connected_to_server.connect(_connected_to_host)
	multiplayer.connection_failed.connect(
		func() -> void: leave("Could not join. Check the address, host lobby and Wi-Fi.")
	)
	multiplayer.server_disconnected.connect(
		func() -> void: leave("The host closed the game. You can host or join again.")
	)
	game.hud.lan_requested.connect(game.hud.show_lan)
	game.hud.host_requested.connect(host)
	game.hud.join_requested.connect(join)
	game.hud.lan_start_requested.connect(begin)
	game.hud.leave_requested.connect(leave)
	game.sound.cue_played.connect(_relay_sound)
	game.hud.message_shown.connect(_relay_message)


func is_guest() -> bool:
	return connected and not hosting


func local_fox() -> ForestFox:
	return members.get(multiplayer.get_unique_id(), game.fox) if connected else game.fox


func host() -> void:
	if connected or connecting:
		return
	peer = ENetMultiplayerPeer.new()
	if peer.create_server(PORT, MAX_PLAYERS + 4, 3) != OK:
		game.hud.lan_error(
			"Cannot host: port %d is in use. Close the other host and try again." % PORT
		)
		return
	multiplayer.multiplayer_peer = peer
	connected = true
	hosting = true
	in_lobby = true
	members = {1: game.fox}
	roster = {1: 1}
	_update_lobby()


func join(address: String) -> void:
	if connected or connecting:
		return
	address = address.strip_edges()
	if not address.is_valid_ip_address():
		game.hud.lan_error("Enter the host's IP address, for example 192.168.1.20.")
		return
	peer = ENetMultiplayerPeer.new()
	if peer.create_client(address, PORT, 3) != OK:
		game.hud.lan_error("Could not open a connection. Check the address and try again.")
		return
	multiplayer.multiplayer_peer = peer
	connecting = true
	_connection_left = 8.0
	game.hud.show_lobby("Connecting to " + address + "…", "", false, 0)


func _connected_to_host() -> void:
	_register.rpc_id(1, PROTOCOL)


@rpc("any_peer", "call_remote", "reliable")
func _register(version: int) -> void:
	if not hosting:
		return
	var id := multiplayer.get_remote_sender_id()
	if members.has(id):
		return
	var reason := ""
	if version != PROTOCOL:
		reason = "Different game versions. Update Emberwood on every computer."
	elif not in_lobby:
		reason = "This adventure has started. Ask the host to open a new lobby."
	elif members.size() >= MAX_PLAYERS:
		reason = "This lobby is full (4 players). Try another host."
	if not reason.is_empty():
		_rejected.rpc_id(id, reason)
		return
	var number := 2
	while roster.values().has(number):
		number += 1
	members[id] = game.add_party_member()
	roster[id] = number
	_update_lobby()


@rpc("authority", "call_remote", "reliable")
func _rejected(reason: String) -> void:
	leave(reason)


func _update_lobby() -> void:
	game.hud.lan_session = true
	game.hud.lan_host = hosting
	_identify_players()
	if in_lobby:
		game.hud.show_lobby(
			"LAN co-op · %d / 4 players" % roster.size(),
			_addresses(),
			hosting,
			roster.size(),
			roster.values()
		)
	if hosting:
		for id: int in recipients():
			if id != 1:
				_lobby.rpc_id(id, roster, in_lobby)


@rpc("authority", "call_remote", "reliable")
func _lobby(players: Dictionary, waiting: bool) -> void:
	connected = true
	connecting = false
	_last_snapshot = 0.0
	in_lobby = waiting
	roster = players
	_sync_members()
	game.hud.lan_session = true
	game.hud.lan_host = false
	_identify_players()
	if waiting:
		game.hud.show_lobby(
			"LAN co-op · %d / 4 players" % roster.size(),
			"You are P%d. Waiting for the host to start." % roster[multiplayer.get_unique_id()],
			false,
			roster.size(),
			roster.values()
		)


func _sync_members() -> void:
	members[1] = game.fox
	for id: int in roster:
		if not members.has(id):
			members[id] = game.add_party_member()
	for id: int in members.keys():
		if not roster.has(id):
			_remove_member(id)
	for member: ForestFox in members.values():
		member.active = false


func _identify_players() -> void:
	for id: int in members:
		members[id].identify(roster[id], id == multiplayer.get_unique_id())


func _addresses() -> String:
	var addresses := PackedStringArray()
	for address in IP.get_local_addresses():
		if (
			address.contains(".")
			and not address.begins_with("127.")
			and not address.begins_with("169.254.")
		):
			addresses.append(address)
	return (
		"Host address: %s\nSame Wi-Fi or wired network · UDP %d"
		% [
			", ".join(addresses) if not addresses.is_empty() else "127.0.0.1 (this computer only)",
			PORT
		]
	)


func begin() -> void:
	if not hosting or not in_lobby or members.size() < 2:
		return
	in_lobby = false
	_update_lobby()
	game.start_run()


func leave(message: String = "") -> void:
	# Replace the multiplayer peer before freeing actors; disconnect callbacks are harmless.
	connected = false
	connecting = false
	hosting = false
	in_lobby = false
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if peer:
		peer.close()
	peer = null
	for member in game.party.duplicate():
		if member != game.fox:
			game.party.erase(member)
			member.queue_free()
	game.fox.network_controlled = false
	game.fox.identify(0, true)
	members.clear()
	roster.clear()
	_last_input.clear()
	_command_times.clear()
	_remote_arrows.clear()
	_incoming_parts.clear()
	_incoming_id = -1
	_previous_mask = -1
	_blocked_mask = 0
	game.hud.lan_session = false
	game.hud.lan_host = false
	game.return_to_title(message)


func _remove_member(id: int) -> void:
	var member: ForestFox = members[id]
	game.party.erase(member)
	member.queue_free()
	members.erase(id)
	roster.erase(id)
	_last_input.erase(id)
	_command_times.erase(id)


func _peer_left(id: int) -> void:
	if not hosting or not members.has(id):
		return
	var number: int = roster[id]
	_remove_member(id)
	_update_lobby()
	game.hud.toast("P%d left the adventure." % number)


func request_action(action: String) -> bool:
	if not is_guest():
		return false
	_action.rpc_id(1, action)
	return true


@rpc("any_peer", "call_remote", "reliable")
func _action(action: String) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not hosting or in_lobby or not members.has(id):
		return
	var now := Time.get_ticks_msec()
	var command_key := str(id) + action
	if now - int(_command_times.get(command_key, 0)) < 100:
		return
	_command_times[command_key] = now
	match action:
		"pause":
			game.pause_run()
		"resume":
			game.resume_run()
		"retry":
			game._respawn("The team returns to camp.")


@rpc("any_peer", "call_remote", "reliable", 1)
func _controls(mask: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not hosting or not members.has(id) or mask < 0 or mask > 31:
		return
	_last_input[id] = Time.get_ticks_msec()
	members[id].accept_input(mask if game.state == game.State.PLAYING else 0)


func _physics_process(delta: float) -> void:
	if connecting:
		_connection_left -= delta
		if _connection_left <= 0:
			leave("Connection timed out. Check the host lobby, Wi-Fi and firewall (UDP %d)." % PORT)
		return
	if not connected:
		return
	if is_guest():
		_last_snapshot += delta
		if not in_lobby and _last_snapshot > 8.0:
			leave("Connection to the host was lost. You can join a new lobby.")
			return
		var physical := 0
		for index in ForestFox.NETWORK_ACTIONS.size():
			if Input.is_action_pressed(ForestFox.NETWORK_ACTIONS[index]):
				physical |= 1 << index
		_blocked_mask &= physical
		if game.state != game.State.PLAYING or in_lobby or not DisplayServer.window_is_focused():
			_blocked_mask |= physical
		var mask := physical & ~_blocked_mask
		_heartbeat -= delta
		if mask != _previous_mask or _heartbeat <= 0:
			_controls.rpc_id(1, mask)
			_previous_mask = mask
			_heartbeat = 0.1
		return
	for id: int in members:
		if id != 1 and Time.get_ticks_msec() - int(_last_input.get(id, 0)) > 500:
			members[id].clear_network_input()
	_snapshot_left -= delta
	if not in_lobby and _snapshot_left <= 0:
		_snapshot_left = SNAPSHOT_INTERVAL
		var data := var_to_bytes(snapshot()).compress(FileAccess.COMPRESSION_DEFLATE)
		_snapshot_id += 1
		var count := ceili(float(data.size()) / PACKET_BYTES)
		for id: int in recipients():
			for part in count:
				_receive_packet.rpc_id(
					id,
					_snapshot_id,
					part,
					count,
					data.slice(part * PACKET_BYTES, (part + 1) * PACKET_BYTES)
				)


func snapshot() -> Dictionary:
	var players := {}
	for id: int in members:
		var member: ForestFox = members[id]
		players[id] = _read(member, FOX_FIELDS)
		players[id].animation = member.sprite.animation
		players[id].frame = member.sprite.frame
	var platforms := []
	for platform in game.level.platforms:
		platforms.append(_read(platform, ["position", "age", "crumble_time", "collision_layer"]))
	var projectiles := {}
	for arrow in game.arrows.get_children():
		projectiles[arrow.get_instance_id()] = _read(arrow, ARROW_FIELDS)
		projectiles[arrow.get_instance_id()].weapon = arrow.weapon_id
	return {
		"stage": game.stage_index,
		"game": _read(game, GAME_FIELDS),
		"level": _read(game.level, LEVEL_FIELDS),
		"players": players,
		"platforms": platforms,
		"equipment": _read(game.equipment, EQUIPMENT_FIELDS),
		"boss": _read(game.boss, BOSS_FIELDS) if is_instance_valid(game.boss) else {},
		"arrows": projectiles
	}


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _receive_packet(sequence: int, index: int, count: int, packet: PackedByteArray) -> void:
	if not is_guest() or sequence < _incoming_id or count < 1 or count > 32:
		return
	if index < 0 or index >= count or packet.size() > PACKET_BYTES:
		return
	if sequence > _incoming_id:
		_incoming_id = sequence
		_incoming_parts.clear()
	_incoming_parts[index] = packet
	if _incoming_parts.size() != count:
		return
	var compressed := PackedByteArray()
	for part in count:
		if not _incoming_parts.has(part):
			return
		compressed.append_array(_incoming_parts[part])
	_incoming_parts.clear()
	var unpacked := compressed.decompress_dynamic(262144, FileAccess.COMPRESSION_DEFLATE)
	if unpacked.is_empty():
		return
	var data: Variant = bytes_to_var(unpacked)
	if data is Dictionary:
		_receive_snapshot(data)


func _receive_snapshot(data: Dictionary) -> void:
	if not is_guest():
		return
	_last_snapshot = 0.0
	if game.state != data.game.state:
		for index in ForestFox.NETWORK_ACTIONS.size():
			if Input.is_action_pressed(ForestFox.NETWORK_ACTIONS[index]):
				_blocked_mask |= 1 << index
	var previous: int = game.state
	var chapter_changed: bool = game.stage_index != data.stage
	if chapter_changed:
		_remote_arrows.clear()
		game._load_chapter(data.stage)
	_apply(game, GAME_FIELDS, data.game)
	_apply(game.level, LEVEL_FIELDS, data.level)
	_apply(game.equipment, EQUIPMENT_FIELDS, data.equipment)
	for id: int in data.players:
		if not members.has(id):
			continue
		var member: ForestFox = members[id]
		_apply(member, FOX_FIELDS, data.players[id])
		if game.reduced_motion and game.invincible_left > 0:
			member.modulate.a = 0.75
		member.sprite.play(data.players[id].animation)
		member.sprite.frame = data.players[id].frame
		member.sprite.flip_h = member.facing < 0
	for index in mini(game.level.platforms.size(), data.platforms.size()):
		var platform: ForestPlatform = game.level.platforms[index]
		_apply(
			platform, ["position", "age", "crumble_time", "collision_layer"], data.platforms[index]
		)
		platform.queue_redraw()
	if is_instance_valid(game.boss):
		_apply(game.boss, BOSS_FIELDS, data.boss)
		game.boss.queue_redraw()
		game.set_arena_wall(game.boss_started and game.boss.engaged and not game.boss.defeated)
	_sync_arrows(data.arrows)
	game._set_state(game.state)
	game._sync_equipment()
	game._refresh_hud()
	if is_instance_valid(game.boss):
		game.hud.update_boss(
			game.boss_started and not game.boss.defeated,
			game.boss.health,
			game.player_health,
			game.boss.status_text(),
			game.boss.guardian_name
		)
	if previous != game.state or chapter_changed or game.hud.lobby_visible:
		game.hud.lobby_visible = false
		_show_state()


func _show_state() -> void:
	match game.state:
		game.State.PAUSED:
			game.hud.show_pause()
		game.State.CHAPTER_COMPLETE:
			game.hud.show_stage_complete(
				game.level.title,
				game.CHAPTER_TITLES[game.stage_index + 1],
				game.format_time(game.elapsed - game.chapter_started_at),
				game.level.taken_gems.size(),
				game.level.gems.size()
			)
		game.State.WON:
			game.show_campaign_results()
		_:
			game.hud.hide_overlay()


func _sync_arrows(data: Dictionary) -> void:
	for id: int in _remote_arrows.keys():
		if not data.has(id):
			if is_instance_valid(_remote_arrows[id]):
				_remote_arrows[id].queue_free()
			_remote_arrows.erase(id)
	for id: int in data:
		if not _remote_arrows.has(id) or not is_instance_valid(_remote_arrows[id]):
			var arrow := ForestArrow.new()
			arrow.setup(
				data[id].position, data[id]._direction, game.level, game.boss, null, data[id].weapon
			)
			arrow.active = false
			game.arrows.add_child(arrow)
			_remote_arrows[id] = arrow
		_apply(_remote_arrows[id], ARROW_FIELDS, data[id])
		_remote_arrows[id].queue_redraw()


func _relay_sound(cue: String) -> void:
	if hosting and not in_lobby:
		for id: int in recipients():
			if id != 1:
				_sound.rpc_id(id, cue)


@rpc("authority", "call_remote", "unreliable")
func _sound(cue: String) -> void:
	game.sound.play(cue)


func _relay_message(message: String) -> void:
	if hosting:
		for id: int in recipients():
			if id != 1:
				_message.rpc_id(id, message)


@rpc("authority", "call_remote", "reliable")
func _message(message: String) -> void:
	game.hud.toast(message)


static func _read(object: Object, fields: Array) -> Dictionary:
	var data := {}
	for field: String in fields:
		data[field] = object.get(field)
	return data


static func _apply(object: Object, fields: Array, data: Dictionary) -> void:
	for field: String in fields:
		if data.has(field):
			object.set(field, data[field])


func recipients() -> Array[int]:
	var ids: Array[int] = []
	if not hosting or not peer:
		return ids
	for id in multiplayer.get_peers():
		if members.has(id) and peer.get_peer(id).get_state() == ENetPacketPeer.STATE_CONNECTED:
			ids.append(id)
	return ids
