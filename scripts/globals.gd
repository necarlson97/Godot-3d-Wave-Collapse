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
	
# Functions for finding by script or class name (see 'matches_class')
func get_matching_node(script, allow_null=false):
	return Globals.static_get_matching_node(get_tree().root, script, allow_null)
func get_matching_nodes(script, allow_empty=false) -> Array:
	return Globals.static_get_matching_nodes(get_tree().root, script, allow_empty)
static func static_get_matching_node(node: Node, script, allow_null=false):
	var res = Globals._static_get_matching_node(node, script)
	assert(res != null or allow_null, "Could not find a %s (%s) = %s"%[script, node, res])
	return res
static func static_get_matching_nodes(node: Node, script, allow_empty=false) -> Array:
	var res = Globals._static_get_matching_nodes(node, script)
	assert(res != [] or allow_empty, "Could not find a %s (%s)"%[script, node])
	return res
static func _static_get_matching_node(node: Node, script):
	if Globals.matches_class(node, script): return node
	for child in node.get_children():
		var res = Globals._static_get_matching_node(child, script)
		if res != null: return res
	return null
static func _static_get_matching_nodes(node: Node, script) -> Array:
	if Globals.matches_class(node, script): return [node]
	var res = []
	for child in node.get_children():
		res += Globals._static_get_matching_nodes(child, script)
	return res
	
static func matches_class(obj, klass) -> bool:
	# A more permissive version of is class that checks:
	# * If obj is of the class (exact or subclass)
	# * If obj matches the class_name (e.g., a string was passed in)
	# * If obj is a node that has a script with the class
	# * If obj is a node that has a script with the class_name
	if klass is String or klass is StringName: return matches_class_name(obj, klass)
	else: return matches_class_type(obj, klass)

static func matches_class_name(obj, klass: String) -> bool:
	# Check if the object itself matches the class or any subclass
	if obj.is_class(klass): return true
	# Traverse through attached script and its base scripts
	var script = obj.get_script()
	while script:
		if klass.to_snake_case() in script.get_path(): return true
		script = script.get_base_script()
	return false
	
static func matches_class_type(obj, klass):
	# Check if the object is an instance of the class or inherits from it
	return is_instance_of(obj, klass)
	
static func set_parent(node, parent, reset_pos=true):
	# Like add_child or reparent, but don't care if it had a parent before
	if node.get_parent(): node.reparent(parent)
	else: parent.add_child(node)
	# Normally, we want to set the position to parent
	if reset_pos: node.position = Vector3(0, 0, 0)
