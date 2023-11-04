extends "res://ui/UILayer.gd"

var multiHustle_UISelectors
var spacebar_handler

var logger = preload("res://MultiHustle/logger.gd")

func _on_game_playback_requested():
	if Network.multiplayer_active and not ReplayManager.resimulating:
		$PostGameButtons.show()
		# Rematch button will probably cause issues, so it's disabled
		#if not quit_on_rematch and not SteamLobby.SPECTATING:
			#$"%RematchButton".show()
		Network.rematch_menu = true

func init(game):
	.init(game)
	turns_taken = {}
	for index in game.players.keys():
		turns_taken[index] = false
	game.turns_taken = turns_taken
	if !is_instance_valid(spacebar_handler):
		spacebar_handler = preload("res://MultiHustle/SpacebarControl.gd").new()
		spacebar_handler.uilayer = self
		add_child(spacebar_handler)

func sync_timer(player_id):
	if Network.multiplayer_active:
		player_id = GetRealID(player_id)
		if player_id == Network.player_id:
			logger.mh_log("syncing timer")
			var timer
			match(player_id):
				1:
					timer = p1_turn_timer
				2:
					timer = p2_turn_timer
				_:
					# TODO
					pass
			Network.sync_timer(player_id, timer.time_left)

func id_to_action_buttons(player_id):
	if multiHustle_UISelectors.selects[1][0].activeCharIndex == player_id:
		return $"%P1ActionButtons"
	if multiHustle_UISelectors.selects[1][0].activeCharIndex == player_id:
		return $"%P2ActionButtons"
	# Emergency Fallback
	if player_id == 1:
		return $"%P1ActionButtons"
	if player_id == 2:
		return $"%P2ActionButtons"
	return null

func _on_player_turn_ready(player_id):
	player_id = GetRealID(player_id)
	._on_player_turn_ready(player_id)

func end_turn_for(player_id):
	player_id = GetRealID(player_id)
	.end_turn_for(player_id)

func _on_turn_timer_timeout(player_id):
	# TODO - Uhh
	player_id = GetRealID(player_id)
	._on_turn_timer_timeout(player_id)

func GetRealID(player_id):
	return multiHustle_UISelectors.selects[player_id][0].activeCharIndex

func submit_dummy_action(player_id):
	#Submits a blank action, used for locking all players in at once and locking in dead players
	.end_turn_for(player_id)
	var fighter = game.get_player(player_id)
	fighter.on_action_selected("Continue", null, null)
	turns_taken[player_id] = true
	Network.turns_ready[player_id] = true

func on_player_actionable():
	Network.action_submitted = false
	multiHustle_UISelectors.ResetGhosts()
	for index in game.players.keys():
		var player = game.players[index]
		if player.game_over:
			submit_dummy_action(index)
		else:
			turns_taken[index] = false
			Network.turns_ready[index] = false
	.on_player_actionable()

func ContinueAll():
	if !Network.multiplayer_active:
		for index in game.players.keys():
			if turns_taken[index] == false:
				submit_dummy_action(index)
