extends "res://Network.gd"

var char_loaded = {}

func is_modded():
	return true

# Util Functions

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