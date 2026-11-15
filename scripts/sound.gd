class_name ForestSound
extends Node
## Short, softly enveloped synthesized cues; no downloaded audio required.

var muted := false
var clips: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var next_voice := 0


func _ready() -> void:
	for n in 6:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -16.0
		add_child(voice)
		players.append(voice)
	clips.jump = _tone([440.0, 610.0], 0.065)
	clips.double = _tone([610.0, 880.0], 0.07)
	clips.gem = _tone([880.0, 1175.0], 0.085)
	clips.acorn = _tone([523.0, 659.0, 784.0, 1047.0], 0.11)
	clips.camp = _tone([392.0, 523.0, 659.0], 0.13)
	clips.hurt = _tone([233.0, 196.0, 146.0], 0.09)
	clips.bounce = _tone([330.0, 523.0, 784.0], 0.06)
	clips.dash = _tone([330.0, 220.0], 0.035)
	clips.shoot = _tone([660.0, 440.0], 0.035)
	clips.spear = _tone([392.0, 247.0], 0.045)
	clips.seed_bomb = _tone([294.0, 440.0, 330.0], 0.04)
	clips.armor = _tone([784.0, 1047.0], 0.07)
	clips.win = _tone([523.0, 659.0, 784.0, 1047.0, 784.0, 1047.0], 0.16)


func play(cue: String) -> void:
	if muted or not clips.has(cue):
		return
	var voice := players[next_voice]
	next_voice = (next_voice + 1) % players.size()
	voice.stream = clips[cue]
	voice.play()


func stop() -> void:
	for voice in players:
		voice.stop()


func _tone(notes: Array, note_duration: float) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(note_duration * rate)
	var data := PackedByteArray()
	data.resize(frames * notes.size() * 2)
	for note in notes.size():
		for frame in frames:
			var t := float(frame) / rate
			var envelope := minf(t / 0.012, 1.0) * pow(1.0 - float(frame) / frames, 1.6)
			var sample := sin(TAU * float(notes[note]) * t) * envelope * 0.65
			data.encode_s16((note * frames + frame) * 2, int(sample * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream
