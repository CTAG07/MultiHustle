extends Node

func installExtension(childScriptPath:String):
	var childScript = ResourceLoader.load(childScriptPath)
	childScript.new()
	var parentScript = childScript.get_base_script()
	if parentScript == null:
		print("Missing dependencies")

	var parentScriptPath = parentScript.resource_path
	print("Installing extension from " + childScriptPath + " to " + parentScriptPath)
	childScript.take_over_path(parentScriptPath)

func _init(modLoader = ModLoader):
	var meta_data = get_meta_data(modLoader, "MultiHustle")
	print("Initializing MultiHustle version %s" % meta_data.version)

	modLoader.installScriptExtension("res://MultiHustle/MLMainHook.gd")
	modLoader.installScriptExtension("res://MultiHustle/main_fake.gd")
	modLoader.installScriptExtension("res://MultiHustle/mechanics/Hitbox.gd")
	modLoader.installScriptExtension("res://MultiHustle/characters/states/ThrowState.gd")
	modLoader.installScriptExtension("res://MultiHustle/characters/swordandgun/states/LassoReel.gd")
	modLoader.installScriptExtension("res://MultiHustle/ui/ActionSelector/ActionButtons.gd")
	modLoader.installScriptExtension("res://MultiHustle/ui/CSS/CharacterSelect.gd")
	modLoader.installScriptExtension("res://MultiHustle/ui/HUD/HudLayer.gd")
	modLoader.installScriptExtension("res://MultiHustle/ui/SteamLobby/LobbyUser.gd")
	modLoader.installScriptExtension("res://MultiHustle/ui/SteamLobby/SteamLobby.gd")
	modLoader.installScriptExtension("res://MultiHustle/ui/UILayer.gd")
	modLoader.installScriptExtension("res://MultiHustle/ui/Chat.gd")
	installExtension("res://MultiHustle/Network.gd")
	ensure_script_override(Network)
	modLoader.installScriptExtension("res://MultiHustle/game.gd")
	modLoader.installScriptExtension("res://MultiHustle/ReplayManager.gd")
	ensure_script_override(ReplayManager)
	modLoader.installScriptExtension("res://MultiHustle/main.gd")
	modLoader.installScriptExtension("res://MultiHustle/SteamLobby.gd")

	#modLoader.saveScene(preload("res://MultiHustle/ui/SteamLobby/LobbyMatch.tscn").instance(), "res://ui/SteamLobby/LobbyMatch.tscn")

	print("Initialized")

func ensure_save(modLoader, path):
	var instance = load(path).instance()
	instance.set_script(load(instance.get_script().resource_path))
	modLoader.saveScene(instance, path)

func get_meta_data(modLoader, name):
	for item in modLoader.active_mods:
		var data = item[1] if typeof(item[1]) != TYPE_STRING else item[2]
		if data.name == name:
		  return data

"""
func _ready():
	override_scene_script("res://ui/CSS/CharacterButton.tscn")
	override_scene_script("res://ui/CSS/CharacterSelect.tscn")
	override_scene_script("res://Game.tscn")

func override_scene_script(scene_path):
	var scene = load(scene_path).instance()
	ModLoader.saveScene(scene, scene_path)
	scene.queue_free()
"""

func ensure_script_override(object):
	#var property_list = object.get_property_list()
	#var properties = {}
	#for property in property_list:
	#	properties[property.name] = object.get(property.name)
	object.set_script(load(object.get_script().resource_path))
	#for property in properties.keys():
	#	object.set(property, properties[property])
