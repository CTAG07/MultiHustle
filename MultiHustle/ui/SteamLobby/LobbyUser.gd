extends "res://ui/SteamLobby/LobbyUser.gd"

signal start_game_pressed()

func init(member):
	.init(member)
	var button = $"%ChallengeButton"
	if !button.disabled && button.visible:
		button.disabled = true
	elif Steam.getLobbyOwner(SteamLobby.LOBBY_ID) == SteamHustle.STEAM_ID:
		button.show()
		button.text = "Start Game"

func on_challenge_pressed():
	emit_signal("start_game_pressed")
	SteamLobby.host_game_vs_all()
