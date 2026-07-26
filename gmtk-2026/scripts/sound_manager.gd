extends Node

@export var sfx_streams: Dictionary[String, AudioStream] = {}
@export var music_streams: Dictionary[String, AudioStream] = {}

@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"

@export var default_sfx_volume: float = -20.0
@export var default_music_volume: float = -30.0

var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = music_bus
	add_child(music_player)

func play_sfx(sound_name: String, volume_db: float = default_sfx_volume, pitch_scale: float = 1.0) -> void:
	if not sfx_streams.has(sound_name) or sfx_streams[sound_name] == null:
		push_warning("SoundManager: no stream assigned for SFX '%s'" % sound_name)
		return

	var player := AudioStreamPlayer.new()
	player.bus = sfx_bus
	player.stream = sfx_streams[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	
func play_music(track_name: String, volume_db: float = default_music_volume, fade_in: float = 0.0) -> void:
	if not music_streams.has(track_name) or music_streams[track_name] == null:
		push_warning("SoundManager: no stream assigned for Music '%s'" % track_name)
		return
		
	var stream := music_streams[track_name]
	if music_player.stream == stream and music_player.playing:
		return
		
	stream.loop = true
	music_player.stream = stream
	if fade_in > 0.0:
		music_player.volume_db = -40.0
		music_player.play()
		var tween := create_tween()
		tween.tween_property(music_player, "volume_db", default_music_volume, fade_in)
	else:
		music_player.volume_db = default_music_volume
		music_player.play()
		
func stop_music() -> void:
	music_player.stop()
