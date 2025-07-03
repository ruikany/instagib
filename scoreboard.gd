extends CanvasLayer

@onready var player_list = $Scoreboard/MarginContainer/VBoxContainer/ScrollContainer/PlayerList

func _ready():
	GameManager.player_score_updated.connect(update_scoreboard)

func update_scoreboard():
	# Clear existing entries
	print("Current Players: ", GameManager.Players) 
	for child in player_list.get_children():
		child.queue_free()
	
	# Get sorted players by score
	var sorted_players = []
	for player_id in GameManager.Players:
		sorted_players.append(GameManager.Players[player_id])
	
	sorted_players.sort_custom(func(a, b): return a.kills > b.kills)
	
	# Populate scoreboard
	for i in range(sorted_players.size()):
		var player = sorted_players[i]
		var row = preload("res://scoreboard_row.tscn").instantiate()
		row.get_node("Row/LabelUsername").text = player.name
		row.get_node("Row/LabelKills").text = str(player.kills)
		row.get_node("Row/LabelDeaths").text = str(player.deaths)
		print("Row nodes: ", row.get_children())
		player_list.add_child(row)
