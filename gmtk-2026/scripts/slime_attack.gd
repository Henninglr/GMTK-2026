extends Area2D

func trigger_aoe() -> void:
	$CollisionShape2D.disabled = false
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("player"):
			body.take_hit()
