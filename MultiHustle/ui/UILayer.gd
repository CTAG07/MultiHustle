extends "res://ui/UILayer.gd"

var multiHustle_UISelectors
var spacebar_handler



var turn_timers = {}

func _on_game_playback_requested():
	if Network.multiplayer_active and not ReplayManager.resimulating:
		$PostGameButtons.show()
		# Rematch button will probably cause issues, so it's disabled
		#if not quit_on_rematch and not SteamLobby.SPECTATING:
			#$"%RematchButton".show()
		Network.rematch_menu = true

func _ready():
	p1_turn_timer.disconnect("timeout", self, "_on_turn_timer_timeout")
	p2_turn_timer.disconnect("timeout", self, "_on_turn_timer_timeout")

func init(game):
	game.turns_taken = {}
	for index in game.players.keys():
		game.turns_taken[index] = false
	.init(game)
	turn_timers = {}
	for index in game.players.keys():
		turn_timers[index] = Timer.new()
		turn_timers[index].connect("timeout", self, "_on_turn_timer_timeout", [index])
		add_child(turn_timers[index], true)
	if !is_instance_valid(spacebar_handler):
		spacebar_handler = preload("res://MultiHustle/SpacebarControl.gd").new()
		spacebar_handler.uilayer = self
		add_child(spacebar_handler)

func sync_timer(player_id):
	Network.log("Syncing time for player id " + str(player_id))
	if Network.multiplayer_active:
		if player_id == Network.player_id:
			Network.log("syncing timer")
			var timer = turn_timers[player_id]
			Network.sync_timer(player_id, timer.time_left)

func _on_sync_timer_request(id, time):
	if not chess_timer:
		return
	var timer = turn_timers[id]
	var paused = timer.paused
	timer.start(time)
	timer.paused = paused

func id_to_action_buttons(player_id):
	if multiHustle_UISelectors.selects[1][0].activeCharIndex == player_id:
		return $"%P1ActionButtons"
	if multiHustle_UISelectors.selects[2][0].activeCharIndex == player_id:
		return $"%P2ActionButtons"
	# Emergency Fallback
	if player_id == 1:
		return $"%P1ActionButtons"
	if player_id == 2:
		return $"%P2ActionButtons"
	return null

func _on_player_turn_ready(player_id):
	turn_timers[player_id].paused = true
	if not is_instance_valid(game):
		return 
	lock_in_tick = game.current_tick
	if player_id != Network.player_id or SteamLobby.SPECTATING:
		$"%TurnReadySound".play()

	game.turns_taken[player_id] = true

func setup_action_buttons():
	$"%P1ActionButtons".init(game, GetRealID(1))
	$"%P2ActionButtons".init(game, GetRealID(2))

func end_turn_for(player_id):
	player_id = GetRealID(player_id)
	turn_timers[player_id].paused = true
	$"%TurnReadySound".play()
	game.turns_taken[player_id] = true
	if player_id == Network.player_id:
		sync_timer(player_id)

func _on_turn_timer_timeout(player_id):
	Network.log("Player " + str(player_id) + " timed out")
	if player_id == Network.player_id:
		if GetRealID(1) == Network.player_id:
			$"%P1ActionButtons".timeout()
		elif GetRealID(2) == Network.player_id:
			$"%P2ActionButtons".timeout()
		else:
			#Simulate the user selecting themselves on the left side, just so that I can properly call the timeout function.
			multiHustle_UISelectors.selects[1][0]._item_selected(Network.player_id)
			$"%P1ActionButtons".timeout()

	var timer = turn_timers[player_id]
	timer.wait_time = MIN_TURN_TIME
	timer.start()
	timer.paused = true

func GetRealID(player_id):
	return multiHustle_UISelectors.selects[player_id][0].activeCharIndex

#Submits a blank action, used for locking all players in at once and locking in dead players
func submit_dummy_action(player_id):
	.end_turn_for(player_id)
	var fighter = game.get_player(player_id)
	fighter.on_action_selected("Continue", null, null)
	game.turns_taken[player_id] = true
	Network.turns_ready[player_id] = true

func ContinueAll():
	if !Network.multiplayer_active:
		for index in game.players.keys():
			if game.turns_taken[index] == false:
				submit_dummy_action(index)

func on_player_actionable():
	Network.action_submitted = false
	multiHustle_UISelectors.ResetGhosts()
	for index in game.players.keys():
		var player = game.players[index]
		if player.game_over:
			submit_dummy_action(index)
		else:
			game.turns_taken[index] = false
			Network.turns_ready[index] = false
	.on_player_actionable()
	if Network.multiplayer_active or SteamLobby.SPECTATING:
		if not game_started:
			for timer in turn_timers.values():
				timer.start()
		else :
			if not chess_timer:
				for timer in turn_timers.values():
					timer.start(turn_time)
			else :
				for timer in turn_timers.values():
					if timer.time_left < MIN_TURN_TIME:
						timer.start(MIN_TURN_TIME)
		for timer in turn_timers.values():
			timer.paused = false
	

func start_timers():
	.start_timers()
	for timer in turn_timers.values():
		timer.paused = false

func set_turn_time(time, minutes = false):
	.set_turn_time(time, minutes)
	for timer in turn_timers.values():
		timer.wait_time = time * (60 if minutes else 1)
