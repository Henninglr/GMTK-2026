extends Node2D

@export var layer_width: float = 1920.0

@export_category("Layer Speeds")
@export var sky_speed: float = 8.0
@export var far_speed: float = 12.0
@export var mid_speed: float = 16.0
@export var near_speed: float = 20.0
@export var foreground_far_speed: float = 24.0
@export var foreground_mid_speed: float = 30.0
@export var foreground_front_speed: float = 36.0

var sky_scroll: float = 0.0
var far_scroll: float = 0.0
var mid_scroll: float = 0.0
var near_scroll: float = 0.0
var foreground_far_scroll: float = 0.0
var foreground_mid_scroll: float = 0.0
var foreground_front_scroll: float = 0.0


func _process(delta: float) -> void:
	sky_scroll = update_layer(
		$BackgroundSky,
		$BackgroundSky2,
		sky_scroll,
		sky_speed,
		delta
	)

	far_scroll = update_layer(
		$BackgroundFar,
		$BackgroundFar2,
		far_scroll,
		far_speed,
		delta
	)

	mid_scroll = update_layer(
		$BackgroundMid,
		$BackgroundMid2,
		mid_scroll,
		mid_speed,
		delta
	)

	near_scroll = update_layer(
		$BackgroundNear,
		$BackgroundNear2,
		near_scroll,
		near_speed,
		delta
	)

	foreground_far_scroll = update_layer(
		$ForegroundFar,
		$ForegroundFar2,
		foreground_far_scroll,
		foreground_far_speed,
		delta
	)

	foreground_mid_scroll = update_layer(
		$ForegroundMid,
		$ForegroundMid2,
		foreground_mid_scroll,
		foreground_mid_speed,
		delta
	)

	foreground_front_scroll = update_layer(
		$ForegroundFront,
		$ForegroundFront2,
		foreground_front_scroll,
		foreground_front_speed,
		delta
	)


func update_layer(
	first_sprite: Sprite2D,
	second_sprite: Sprite2D,
	current_scroll: float,
	speed: float,
	delta: float
) -> float:
	current_scroll += speed * delta

	if current_scroll >= layer_width:
		current_scroll -= layer_width

	var snapped_scroll: float = floor(current_scroll)

	first_sprite.position.x = -snapped_scroll
	second_sprite.position.x = layer_width - snapped_scroll

	return current_scroll
