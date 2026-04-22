extends CanvasGroup


func write_health(num: int):
	$text.text = "%d/100" % [num]

func set_bar(num: int):
	$Bar.frame = num

func shake():
	if not $BarShake.is_playing():
		$BarShake.play("shake")
