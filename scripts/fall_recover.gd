extends Node3D

func _process(delta: float) -> void:
	if global_position.y < -100:
		# TODO is this the best way to do this kind of node-component coding?
		get_parent().global_position = Vector3(0, 1, 0)
