extends "res://ui/ActionSelector/ActionButtons.gd"

var logger = preload("res://MultiHustle/logger.gd")

# Hooked for debugging purposes
func init(game, id):
	logger.mh_log("Init called for action buttons! Game: " + str(game) + " ID: " + str(id))
	reset()
	self.game = game
	fighter = game.get_player(id)
	$"%DI".visible = fighter.di_enabled
	fighter_extra = fighter.player_extra_params_scene.instance()
	fighter_extra.connect("data_changed", self, "extra_updated")
	game.connect("forfeit_started", self, "_on_forfeit_started")
	fighter_extra.set_fighter(fighter)
	turbo_mode = fighter.turbo_mode
	Network.action_button_panels[id] = self
	buttons = []


	var states = []
	for category in fighter.action_cancels:
		for state in fighter.action_cancels[category]:
			if state.show_in_menu and not state in states:
				states.append(state)
				create_button(state.name, state.title, state.get_ui_category(), state.data_ui_scene, BUTTON_SCENE, state.button_texture, state.reversible, state.flip_icon, state)

	sort_categories()
	connect("action_selected", fighter, "on_action_selected")
	fighter.connect("action_selected", self, "_on_fighter_action_selected")
	fighter.connect("forfeit", self, "_on_fighter_forfeit")
	hide()
	$"%TopRowDataContainer".add_child(fighter_extra)
	if player_id == 1:


		$"%CategoryContainer".move_child($"%TurnButtons", $"%CategoryContainer".get_children().size() - 1)
		$"%TopRowDataContainer".move_child(fighter_extra, 2)
	else :
		$"%TopRowDataContainer".move_child(fighter_extra, 0)
	continue_button = create_button("Continue", "Hold", "Movement", null, preload("res://ui/ActionSelector/ContinueButton.tscn"), null, false)
	continue_button.get_parent().remove_child(continue_button)
	continue_button["custom_fonts/font"] = null
	$"%TurnButtons".add_child(continue_button)
	$"%TurnButtons".move_child(continue_button, 1)

	logger.mh_log("Init finished for action buttons! Game: " + str(game) + " ID: " + str(id))

func reset():
	for button_category_container in button_category_containers.values():
		button_category_container.free()
	for button in buttons:
		if is_instance_valid(button):
			if button.data_node:
				button.data_node.free()
			button.free()
	for data in $"%DataContainer".get_children():
		data.free()
	if fighter_extra:
		fighter_extra.free()
	
	button_category_containers.clear()



	current_action = null
	current_button = null
	last_button = null
	forfeit = false
	buttons = []

func get_extra()->Dictionary:
	if is_instance_valid(game):
		# I now get opponent first, just to be sure, for some reason.
		var extra = {
			"opponent":game.current_opponent_indicies[fighter.id]
		}
		extra.merge(.get_extra())
		return extra
	else:
		logger.mh_log("game was somehow null")
		return .get_extra()

func GetRealID():
	return fighter.id

func create_category(category, category_int = - 1):
	var scene = BUTTON_CATEGORY_CONTAINER_SCENE.instance()
	button_category_containers[category] = scene
	scene.category_int = category_int
	scene.show_behind_parent = true
	scene.init(category)

	scene.connect("prediction_selected", self, "_on_prediction_selected", [category])
	scene.game = game
	scene.player_id = GetRealID()
	$"%CategoryContainer".add_child(scene)

func on_action_submitted(action, data = null, extra = null):
	active = false
	extra = get_extra() if extra == null else extra

	var button_manager = Network.multihustle_action_button_manager
	var left = button_manager.action_buttons_left
	var right = button_manager.action_buttons_right
	var id = GetRealID()
	if left.has(id):
		left[id].disable_select()
	if right.has(id):
		right[id].disable_select()
	emit_signal("turn_ended")

	emit_signal("action_selected", action, data, extra)
	if not SteamLobby.SPECTATING:
		if Network.player_id == GetRealID():
			Network.submit_action(action, data, extra)

func disable_select():
	$"%SelectButton".disabled = true
	$"%SelectButton".shortcut = null

func update_select_button():
	var user_facing = game.singleplayer or Network.player_id == GetRealID()
	if not user_facing:
		$"%SelectButton".disabled = true
	else :
		$"%SelectButton".disabled = game.spectating or locked_in

func activate(refresh = true):
	if visible and refresh:
		return

	active = true
	locked_in = false


	if is_instance_valid(fighter):
		$"%DI".set_label("DI" + " x%.1f" % float(fighter.get_di_scaling(false)))
		var last_action_name = ReplayManager.get_last_action(fighter.id)

		if last_action_name and fighter.state_machine.states_map.has(last_action_name.action):
			last_action_name = last_action_name.action
		else :
			last_action_name = fighter.current_state().name

		var last_action:CharacterState = fighter.state_machine.states_map[last_action_name]
		$"%LastMoveTexture".texture = last_action.button_texture
		$"%LastMoveLabel".text = last_action.title if last_action.title else last_action.name
		$"%LastMoveTexture".visible = not last_action.is_hurt_state
		$"%LastMoveLabel".visible = not last_action.is_hurt_state

	var user_facing = game.singleplayer or Network.player_id == GetRealID()
	if Network.multiplayer_active:
		if user_facing:
			$"%YouLabel".show()
			modulate = Color.white
			Network.action_submitted = false
		else :
			$"%YouLabel".hide()
			modulate = Color("b3b3b3")
	else :
		$"%YouLabel".hide()

	if game.current_tick == 0:
		$"%UndoButton".set_disabled(true)
	else :
		$"%UndoButton".set_disabled(false)
	if Network.multiplayer_active or SteamLobby.SPECTATING:
		$"%UndoButton".hide()

	$"%ReverseButton".set_disabled(true)
	$"%ReverseButton".pressed = false
	$"%FeintButton".pressed = false

	current_action = null
	current_button = null


	show()










	if (not user_facing) or game.turns_taken[fighter.id] or fighter.game_over:
		$"%SelectButton".disabled = true
	else :
		$"%SelectButton".disabled = game.spectating

	fighter_extra.hide()
	update_buttons(refresh)


	if not fighter.busy_interrupt:
		fighter_extra.show()
		fighter_extra.show_behind_parent = true
		fighter_extra.show_options()

	fighter_extra.reset()

	if fighter.dummy:
		on_action_submitted("ContinueAuto", null)
		hide()

	if fighter.will_forfeit:
		on_action_submitted("Forfeit", null, null)
		fighter.dummy = true

	fighter.any_available_actions = any_available_actions
	if user_facing and $"%AutoButton".pressed:
		if not any_available_actions:
			logger.mh_log("no available actions!")
			on_action_submitted("Continue", null)
			current_action = "Continue"

	$"%ReverseButton".hide()
	yield (get_tree(), "idle_frame")

	$"%ReverseButton".show()
	if not refresh:
		return
	button_pressed = false
	send_ui_action("Continue")
	if user_facing:
		if Network.multiplayer_active:
			yield (get_tree().create_timer(0.25), "timeout")
		$"%SelectButton".shortcut = preload("res://ui/ActionSelector/SelectButtonShortcut.tres")






	if player_id == 1:
		if Network.p1_undo_action:
			var input = Network.p1_undo_action
			on_action_submitted(input["action"], input["data"], input["extra"])
			Network.p1_undo_action = null
	if player_id == 2:
		if Network.p2_undo_action:
			var input = Network.p2_undo_action
			on_action_submitted(input["action"], input["data"], input["extra"])
			Network.p2_undo_action = null

func reset():
	visible = false
	if is_instance_valid(fighter_extra):
		if fighter_extra.is_connected("data_changed", self, "send_ui_action"):
			fighter_extra.disconnect("data_changed", self, "send_ui_action")
	else:
		fighter_extra = null
	if is_instance_valid(game):
		if game.is_connected("forfeit_started", self, "_on_forfeit_started"):
			game.disconnect("forfeit_started", self, "_on_forfeit_started")
	if is_connected("action_selected", fighter, "on_action_selected"):
		disconnect("action_selected", fighter, "on_action_selected")
	if is_instance_valid(fighter):
		if fighter.is_connected("action_selected", self, "_on_fighter_action_selected"):
			fighter.disconnect("action_selected", self, "_on_fighter_action_selected")
		if fighter.is_connected("forfeit", self, "_on_fighter_forfeit"):
			fighter.disconnect("forfeit", self, "_on_fighter_forfeit")
	else:
		fighter = null
	.reset()
