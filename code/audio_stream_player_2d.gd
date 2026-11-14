extends AudioStreamPlayer2D

func _ready():
	var bgm_stream = load("res://A_Bit_Of_Hope_David_Fesliyan.mp3")
	if bgm_stream == null:
		print("音频加载失败，请检查路径与导入设置")
		return
	# MP3 只需要这一句开启循环
	bgm_stream.loop = true
	stream = bgm_stream
	play()

func stop_bgm():
	stop()
