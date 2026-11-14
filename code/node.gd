extends Node

var slash: AudioStream
var dodge: AudioStream
var pistol: AudioStream
var hurt: AudioStream
var smile: AudioStream
var light: AudioStream
var rain: AudioStream
var rain_player: AudioStreamPlayer = null # 循环雨声专用播放器

func _ready():
	slash = load("res://m_1.wav")
	dodge = load("res://m_2.wav")
	smile = load("res://universfield-slime-impact-352473.wav")
	light= load ("res://dragon-studio-button-press-386165.mp3")
	rain= load("res://rain-soft-gentle.mp3")

func play_sfx(stream: AudioStream):
	if stream == null:
		print("❌ stream是空！")
		return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_slash():
	print("👉 调用 play_slash")
	play_sfx(slash)
func play_dodge():
	play_sfx(dodge)
func play_pistol():
	play_sfx(pistol)
func play_hurt():
	play_sfx(hurt)
func play_smile():
	play_sfx(smile)
func play_light():
	play_sfx(light)

# 控制循环雨声，给雨滴脚本调用
func set_rain_volume(vol: float):
	vol = clamp(vol, 0.0, 1.0)
	if rain == null:
		return
	if rain_player == null:
		rain_player = AudioStreamPlayer.new()
		rain_player.stream = rain
		add_child(rain_player)
		rain_player.finished.connect(func():
			if rain_player.volume_db > -60.0:
				rain_player.play()
		)
	
	rain_player.volume_db = linear_to_db(vol) + 3.6
	if vol > 0.01 and not rain_player.playing:
		rain_player.play()
	elif vol <= 0.01 and rain_player.playing:
		rain_player.stop()
