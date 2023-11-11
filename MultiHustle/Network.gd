extends "res://Network.gd"

var char_loaded = {}

func is_modded():
	return true

#Oh my god I hate this so much but it somehow works in testing dpajwojiosdfnikvkvknovnkonkoiopsja
var file_path = "user://logs/mhlogs" + Time.get_time_string_from_unix_time(int(Time.get_unix_time_from_system()-(Time.get_ticks_msec()/1000))).replace(":", ".") + ".log"
var logger = preload("res://MultiHustle/logger.gd")

# Util Functions

func log(msg):
	logger.mh_log("[" + str(float(Time.get_ticks_msec())/1000.0) + "] " + msg, file_path)

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

func has_char_loader()->bool:
	return has_method("character_list")

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
	if ticks[1] == ticks[2]:
		turn_synced = true
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

func rpc_(function_name:String, arg = null, type = "remotesync"):
	Network.log("Sending rpc! Function: " + str(function_name) + " | Args: " + str(arg))
	.rpc_(function_name, arg, type)

remotesync func multiplayer_turn_ready(id):
	Network.turns_ready[id] = true
	Network.log("Turn ready for player " + str(id) + " | Turns ready: " + str(Network.turns_ready))
	emit_signal("player_turn_ready", id)
	if steam:
		SteamLobby.spectator_turn_ready(id)
	var ready = true
	for r in Network.turns_ready.values():
		if !r:
			ready = false
			break
	if ready:
		action_submitted = true
		Network.log("Sending action, action: " + str(action_inputs[player_id]))
		last_action = action_inputs[player_id]
		if is_instance_valid(game):
			last_action_sent_tick = game.current_tick
		send_current_action()
		possible_softlock = true
		emit_signal("turn_ready")
		turn_synced = false
		send_ready = true

func sync_tick():
	Network.log("Telling opponent im ready")
	rpc_("opponent_tick", null, "remote")
	pass

remote func opponent_tick():
	print("Opponent is ready")
	yield (get_tree(), "idle_frame")
	if is_instance_valid(game):
		game.network_simulate_ready = true

func reset_action_inputs():
	turns_ready = {}
	action_inputs = {}
	for player in game.players.keys():
		action_inputs[player] = {
			"action":null, 
			"data":null, 
			"extra":null, 
		}
		turns_ready[player] = false