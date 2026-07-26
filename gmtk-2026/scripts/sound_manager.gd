extends Node

@export var sfx_streams: Dictionary[String, AudioStream] = {}
@export var music_streams: Dictionary[String, AudioStream] = {}

@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"

@export var default_sfx_volume: float = -20.0
@export var default_music_volume: float = -20.0

@export var sprint_pitch_semitones: float = 4.0

var music_player: AudioStreamPlayer
var walk_player: AudioStreamPlayer
var pitch_effect: AudioEffectPitchShift

var is_walking: bool = false

var is_sprinting: bool = false:
	set(value):
		is_sprinting = value
		if music_player:
			if is_sprinting:
				pitch_effect.pitch_scale = _semitones_to_ratio(sprint_pitch_semitones)
			else:
				pitch_effect.pitch_scale = 1.0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = music_bus
	add_child(music_player)
	
	walk_player = AudioStreamPlayer.new()
	walk_player.stream = sfx_streams["player_walk"]
	walk_player.bus = sfx_bus
	walk_player.volume_db = -16
	walk_player.pitch_scale = 0.90
	add_child(walk_player)
	
	pitch_effect = AudioEffectPitchShift.new()
	pitch_effect.pitch_scale = 1.0
	_add_effect_to_bus("Master", pitch_effect)
	
func _add_effect_to_bus(bus_name: String, effect: AudioEffect) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_warning("SoundManager: bus '%s' not found" % bus_name)
		return
	AudioServer.add_bus_effect(bus_idx, effect)

func _semitones_to_ratio(semitones: float) -> float:
	return pow(2.0, semitones / 12.0)

func play_sfx(sound_name: String, volume_db: float = default_sfx_volume, pitch_scale: float = 1.0) -> void:
	if not sfx_streams.has(sound_name) or sfx_streams[sound_name] == null:
		push_warning("SoundManager: no stream assigned for SFX '%s'" % sound_name)
		return
		
	# Create audio player and connect sound
	var player := AudioStreamPlayer.new()
	player.bus = sfx_bus
	player.stream = sfx_streams[sound_name]
	
	# Set volume
	player.volume_db = volume_db
	
	
	player.pitch_scale = pitch_scale
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	
func play_music(track_name: String, volume_db: float = default_music_volume, fade_in: float = 0.0) -> void:
	if not music_streams.has(track_name) or music_streams[track_name] == null:
		push_warning("SoundManager: no stream assigned for Music '%s'" % track_name)
		return
		
	
	# Check music is not already playing
	var stream := music_streams[track_name]
	if music_player.stream == stream and music_player.playing:
		return
			
	# Fade in music
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
	
func play_walk(is_moving: bool) -> void:
	# check for state change
	if is_moving and not is_walking:
		is_walking = true
		walk_player.play()
	elif is_walking and not is_moving:
		is_walking = false
		walk_player.stop()
	else:
		return
		
	
