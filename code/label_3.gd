extends Label

func _ready():
	text = "游玩时间: " + GameState.format_play_time(GameState.play_time)
	GameState.play_time_changed.connect(_update_time)

func _update_time(sec: float):
	text = "游玩时间: " + GameState.format_play_time(sec)
