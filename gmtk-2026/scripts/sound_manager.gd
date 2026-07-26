extends Node

@export var sfx_streams: Dictionary[String, AudioStream] = {}
@export var music_streams: Dictionary[String, AudioStream] = {}

@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"

var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = music_bus
	add_child(music_player)
