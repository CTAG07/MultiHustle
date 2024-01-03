extends Node

func installExtension(childScriptPath:String):
	var childScript = ResourceLoader.load(childScriptPath)
	childScript.new()
	var parentScript = childScript.get_base_script()
	if parentScript == null:
		print("Missing dependencies")

	var parentScriptPath = parentScript.resource_path
	childScript.take_over_path(parentScriptPath)

func _init(modLoader = ModLoader):
	var meta_data = get_meta_data(modLoader, "MultiHustle")
	print("Initializing MultiHustle version %s" % meta_data.version)
	installExtension("res://MultiHustle/MLMainHook.gd")
	installExtension("res://MultiHustle/main_fake.gd")
	installExtension("res://MultiHustle/mechanics/Hitbox.gd")
	installExtension("res://MultiHustle/characters/states/ThrowState.gd")
	installExtension("res://MultiHustle/characters/swordandgun/states/LassoReel.gd")
	installExtension("res://MultiHustle/ui/ActionSelector/ActionButtons.gd")
	installExtension("res://MultiHustle/ui/CSS/CharacterSelect.gd")
	installExtension("res://MultiHustle/ui/HUD/HudLayer.gd")
	installExtension("res://MultiHustle/ui/SteamLobby/LobbyUser.gd")
	installExtension("res://MultiHustle/ui/SteamLobby/SteamLobby.gd")
	installExtension("res://MultiHustle/ui/UILayer.gd")
	installExtension("res://MultiHustle/ui/Chat.gd")
	installExtension("res://MultiHustle/Network.gd")
	installExtension("res://MultiHustle/game.gd")
	installExtension("res://MultiHustle/ReplayManager.gd")
	installExtension("res://MultiHustle/main.gd")
	installExtension("res://MultiHustle/SteamLobby.gd")

	#modLoader.saveScene(preload("res://MultiHustle/ui/SteamLobby/LobbyMatch.tscn").instance(), "res://ui/SteamLobby/LobbyMatch.tscn")

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
