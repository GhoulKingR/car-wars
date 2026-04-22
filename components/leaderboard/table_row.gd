extends HBoxContainer

@onready var pos_element = $Pos
@onready var nickname_element = $Name
@onready var kills_element = $Kills
@onready var deaths_element = $Deaths
@onready var score_element = $Score

func write_data(pos: int, data: LeaderboardItem):
	pos_element.text = var_to_str(pos)
	nickname_element.text = data.nickname
	kills_element.text = var_to_str(data.kills)
	deaths_element.text = var_to_str(data.deaths)
	score_element.text = var_to_str(data.score)
