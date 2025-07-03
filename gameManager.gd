extends Node

var Players = {}

signal player_score_updated

@rpc("any_peer", "reliable")
func update_player_score(pid, kills, deaths):
	if Players.has(pid):
		Players[pid].kills = kills
		Players[pid].deaths = deaths
	player_score_updated.emit()
