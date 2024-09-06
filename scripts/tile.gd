extends Node3D

class_name Tile

# Boundaries for each side of the tile
var x_plus : String
var x_minus : String
var z_plus : String
var z_minus : String
var y_plus : String
var y_minus : String

# Whether the tile can be rotated on the z-axis
var rotatable : bool = true

func _to_string():
	# TODO add name from blender object
	return "%s x(-%s, +%s) z(-%s, +%s) y(-%s, +%s)" % [
		name, x_minus, x_plus, z_minus, z_plus, y_minus, y_plus
	]

func get_variants() -> Array[Tile]:
	# Return all options for a tile - all rotations
	# TODO in the future, we could have other things that add procedual variants
	var variants: Array[Tile]
	if !rotatable:
		return [self]
	
	# Create variants by rotating 0, 90, 180, 270 degrees
	for angle in [0, 90, 180, 270]:
		var rotated_tile = rotate_tile(angle)
		variants.append(rotated_tile)

	return variants

# Helper function to rotate the tile by a given angle and return a new tile instance
func rotate_tile(angle_degrees: int) -> Tile:
	var rotated_tile = self.duplicate()

	# Rotate boundaries: boundaries on x and z axes are swapped based on the angle
	var boundries = [z_plus, x_minus, z_minus, x_plus]

	# Compute new indices based on rotation (counter-clockwise)
	var rotation_steps = int(angle_degrees / 90)
	boundries = rotate_array(boundries, rotation_steps)

	# Set the rotated boundaries
	rotated_tile.z_plus = boundries[0]
	rotated_tile.x_minus = boundries[1]
	rotated_tile.z_minus = boundries[2]
	rotated_tile.x_plus = boundries[3]

	# Keep y boundaries the same
	rotated_tile.y_plus = y_plus
	rotated_tile.y_minus = y_minus

	# Rotate the visual 3D transform using Godot's Basis rotation
	for child in rotated_tile.get_children():
		child.transform.basis = child.transform.basis.rotated(
			Vector3(0, 1, 0), deg_to_rad(angle_degrees)
		)
	
	rotated_tile.name += " %s" % angle_degrees

	return rotated_tile

# Utility function to rotate an array by n steps
func rotate_array(arr: Array, steps: int) -> Array:
	return arr if steps == 0 else arr.slice(steps) + arr.slice(0, steps)

func _process(delta: float) -> void:
	#var label = get_node_or_null("my_name") as Label3D
	#if label == null:
		#label = Label3D.new()
		#label.name = "my_name"
		#add_child(label)
		#label.text = self.name
		#label.position = Vector3(0, .3, 0)
		
	for boundary in Globals.BOUNDARIES:
		_update_boundary_label(boundary)
	
func _update_boundary_label(boundary: Globals.Boundary) -> void:
	var label = get_node_or_null(boundary.var_name) as Label3D
	if label == null:
		label = Label3D.new()
		label.name = boundary.var_name
		add_child(label)
		label.text = self.get(boundary.var_name)
		var label_offset = (boundary.offset * 0.8) + Vector3(0, 0.2, 0)
		label.position = label_offset
