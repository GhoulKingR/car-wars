extends ScrollContainer

@onready var rows = [
	$VBoxContainer/TableRow1,
	$VBoxContainer/TableRow2,
	$VBoxContainer/TableRow3,
	$VBoxContainer/TableRow4,
	$VBoxContainer/TableRow5,
	$VBoxContainer/TableRow6,
	$VBoxContainer/TableRow7,
	$VBoxContainer/TableRow8,
	$VBoxContainer/TableRow9,
	$VBoxContainer/TableRow10,
	$VBoxContainer/TableRow11,
	$VBoxContainer/TableRow12,
	$VBoxContainer/TableRow13,
	$VBoxContainer/TableRow14,
	$VBoxContainer/TableRow15,
	$VBoxContainer/TableRow16,
	$VBoxContainer/TableRow17,
	$VBoxContainer/TableRow18,
	$VBoxContainer/TableRow19,
	$VBoxContainer/TableRow20,
	$VBoxContainer/TableRow21,
]

func _ready() -> void:
	scroll_vertical = 0

func write_leaderboard(leaderboard_data : Array[LeaderboardItem]):
	for i in range(leaderboard_data.size()):
		rows[i].write_data(i + 1, leaderboard_data[i])
