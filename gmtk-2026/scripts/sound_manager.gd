class_name SoundManager
extends Node

enum Sfx {
	HIT,
	HURT,
	ATTACK,
	DEATH,
	FOOTSTEP,
	PICKUP,
}

enum Music {
	MAIN_THEME,
	DUNGEON,
	BOSS,
}

@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"

# Pool for overlapping sound effects
var sfx_players: Array[AudioStreamPlayer] = []
const max_sfx_pool_size : int = 8

var music_player: AudioStreamPlayer

func _ready() -> void:
	for i in range(sfx_pool_size):
		var audio_player := AudioStreamPlayer.new()
		player.bus = sfx_bus
		add_child(player)
		sfx_players
