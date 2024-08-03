extends "res://cl_port/Network.gd"

var char_loaded = {}

var sync_unlocks = {}

var lock_sync_unlocks = true

#Oh my god I hate this so much but it somehow works in testing dpajwojiosdfnikvkvknovnkonkoiopsja
var mh_file_path = "user://logs/mhlogs" + Time.get_time_string_from_unix_time(int(Time.get_unix_time_from_system()-(Time.get_ticks_msec()/1000))).replace(":", ".") + ".log"
var net_file_path = "user://logs/netlogs" + Time.get_time_string_from_unix_time(int(Time.get_unix_time_from_system()-(Time.get_ticks_msec()/1000))).replace(":", ".") + ".log"
var logger = preload("res://MultiHustle/logger.gd")

# Util Functions

"""
Quick note from CTAG: I use a lot of questionable logic to sorta ignore dead players while still sending them actions.
Dead players could get desynced and nobody would be the wiser besides the dead player.
If someone comes along who wants to fix this and make it properly ignore/remove/make them spectators, go ahead.
But I'm fairly confident that this should cover for now.
"""

func log(msg, net = false):
	if net:
		logger.mh_log("[" + str(float(Time.get_ticks_msec())/1000.0) + "] " + msg, net_file_path)
	else:
		logger.mh_log("[" + str(float(Time.get_ticks_msec())/1000.0) + "] " + msg, mh_file_path)

func get_all_pairs(list):
	var idx = 0
	var listEnd = len(list)
	var listEndMinus = listEnd - 1
	var result = []
	for p1 in list:
		for p2 in list.slice(idx+1, listEnd):
			result.append([p1, p2])
		idx = idx + 1
		if (idx == listEndMinus):
			break
	return result

# Deprecated, base game always has it now.
func has_char_loader()->bool:
	return true

func ensure_script_override(object):
	#var property_list = object.get_property_list()
	#var properties = {}
	#for property in property_list:
	#	properties[property.name] = object.get(property.name)
	object.set_script(load(object.get_script().resource_path))
	#for property in properties.keys():
	#	object.set(property, properties[property])

func pid_to_username(player_id):
	if !is_instance_valid(game):
		return ""
	if SteamLobby.SPECTATING or !network_ids.has(player_id):
		return Global.current_game.match_data.user_data["p" + str(player_id)]
	if direct_connect:
		return players[network_ids[opponent_player_id(player_id)]]
	return players[network_ids[player_id]]

remotesync func end_turn_simulation(tick, player_id):
	Network.log("Ending turn simulation for player " + str(player_id) + " at tick " + str(tick))
	ticks[player_id] = tick
	turn_synced = true
	for v in ticks.values():
		if v != tick:
			turn_synced = false
	if turn_synced:
		send_ready = false
		emit_signal("player_turns_synced")

func submit_action(action, data, extra):
	if multiplayer_active:
		action_inputs[player_id]["action"] = action
		action_inputs[player_id]["data"] = data
		action_inputs[player_id]["extra"] = extra
		rpc_("multiplayer_turn_ready", player_id)
		Network.log("Action ready for player " + str(player_id))

func send_current_action():
	if last_action:
		rpc_("send_action", [last_action["action"], last_action["data"], last_action["extra"], player_id], "remote")

remotesync func multiplayer_turn_ready(id):
	turns_ready[id] = true
	Network.log("Turn ready for player " + str(id) + " | Turns ready: " + str(turns_ready))
	emit_signal("player_turn_ready", id)
	if steam:
		SteamLobby.spectator_turn_ready(id)
	for r in turns_ready.values():
		if !r:
			return
	action_submitted = true
	last_action = action_inputs[player_id]
	if is_instance_valid(game):
		last_action_sent_tick = game.current_tick
	send_current_action()
	possible_softlock = true
	emit_signal("turn_ready")
	turn_synced = false
	send_ready = true

func sync_tick():
	lock_sync_unlocks = false
	if not game.players[Network.player_id].game_over:
		Network.log("Telling opponent im ready")
		rpc_("mh_opponent_tick", player_id, "remote")

remote func mh_opponent_tick(id):
	Network.log("Opponent is ready")
	yield (get_tree(), "idle_frame")
	if is_instance_valid(game):
		game.network_simulate_readies[id] = true

func reset_action_inputs():
	turns_ready = {}
	action_inputs = {}
	for player in game.players.keys():
		if game.players[player].game_over:
			action_inputs[player] = {
				"action":"ContinueAuto", 
				"data":null, 
				"extra":null, 
			}
			turns_ready[player] = true
		else:
			action_inputs[player] = {
				"action":null, 
				"data":null, 
				"extra":null, 
			}
			turns_ready[player] = false

func sync_unlock_turn():
	Network.log("telling opponent we are actionable")
	
	rpc_("opponent_sync_check_unlock", null, "remote")

remote func opponent_sync_check_unlock():
	Network.log("Opponent is actionable")
	while is_instance_valid(game) and not game.game_paused:
		yield (get_tree(), "idle_frame")
	Network.log("So are we")
	sync_unlocks[player_id] = true
	rpc_("mh_opponent_sync_unlock", player_id, "remote")

remote func mh_opponent_sync_unlock(id):
	if !lock_sync_unlocks:
		Network.log("Opponent sync unlocked, ID: " + str(id))
		sync_unlocks[id] = true
		Network.log("Sync unlocks: " + str(sync_unlocks))
		var done = true
		for value in sync_unlocks.values():
			if !value:
				done = value
				break
		if done:
			for key in sync_unlocks.keys():
				if not game.players[key].game_over:
					sync_unlocks[key] = false
			can_open_action_buttons = true
			Network.log("Unlocking action buttons")
			emit_signal("force_open_action_buttons")
			lock_sync_unlocks = true

remote func player_disconnected(id):
	if not (id in players):
		return 
	if Global.css_open:
		if steam and game.players[id].hp > 0:
			game.players[id].forfeit()
	emit_signal("player_disconnected")
	if is_host():
		if players.has(id):
			emit_signal("game_error", "Player " + players[id] + " disconnected")
	else:
		unregister_player(id)
	if not steam:
		end_game()
