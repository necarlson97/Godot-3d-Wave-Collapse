extends Node

var BOUNDARIES = []

# A quick helper class for the 6 cardinal boundries on each tile
class Boundary:
	var var_name: String
	var short_name: String
	var offset: Vector3
	static var ALL: Array[Boundary]
	
	func _init(var_name: String, short_name: String, offset: Vector3):
		self.var_name = var_name
		self.short_name = short_name
		self.offset = offset
		
	func get_neighbor_boundry():
		# So a +x is always going to care about it's
		# -x neighbor - return that boundry
		for b in ALL:
			if self != b and short_name[0] == b.short_name[0]:
				return b
		assert(false, "Couldn't find neighbor for %s (%s)"%[self, ALL])
		
	func _to_string() -> String:
		return "%s %s"%[short_name, offset]

const TILE_SIZE = 4

func _init():
	# Initialize the boundaries array when the game starts
	Boundary.ALL = [
		Boundary.new("x_plus", "x+", Vector3(TILE_SIZE / 2, 0, 0)),
		Boundary.new("x_minus", "x-", Vector3(-TILE_SIZE / 2, 0, 0)),
		Boundary.new("z_plus", "z+", Vector3(0, 0, TILE_SIZE / 2)),
		Boundary.new("z_minus", "z-", Vector3(0, 0, -TILE_SIZE / 2)),
		Boundary.new("y_plus", "y+", Vector3(0, TILE_SIZE / 2, 0)),
		Boundary.new("y_minus", "y-", Vector3(0, -TILE_SIZE / 2, 0))
	]
	BOUNDARIES = Boundary.ALL
