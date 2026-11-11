extends Node
var music: AudioStreamPlayer
var voices: Array = []
var streams: Dictionary = {}
var last_collision = -1000

func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.stream = load("res://assets/audio/workshop.wav")
	add_child(music)
	music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.stream.loop_begin = 0
	music.stream.loop_end = int(music.stream.get_length()*music.stream.mix_rate)
	for name in ["ui","drop","impact","heavy","select","extract","recover","fail","complete"]:
		streams[name] = load("res://assets/audio/"+name+".wav")
	for i in range(8):
		var p = AudioStreamPlayer.new()
		p.bus = "Effects"
		add_child(p)
		voices.append(p)

func settings(s: Dictionary) -> void:
	for pair in [["Music",s.music],["Effects",s.effects]]:
		var idx = AudioServer.get_bus_index(pair[0])
		AudioServer.set_bus_volume_db(idx,linear_to_db(maxf(float(pair[1]),0.0001))-6)
		AudioServer.set_bus_mute(idx,float(pair[1])<=0.001)

func play(kind: String) -> void:
	if not streams.has(kind):
		return
	if kind in ["impact","heavy"]:
		var now = Time.get_ticks_msec()
		if now-last_collision < 120:
			return
		last_collision = now
	for p in voices:
		if not p.playing:
			p.stream = streams[kind]
			p.pitch_scale = randf_range(0.96,1.04) if kind in ["impact","heavy"] else 1.0
			p.play()
			return

func stop_effects() -> void:
	for p in voices:
		p.stop()

func _exit_tree() -> void:
	music.stop()
	music.stream = null
	stop_effects()
