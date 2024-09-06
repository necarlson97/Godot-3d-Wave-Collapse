# The Wave Function Collapse solver
extends Node3D
class_name Solver

var palette: Array[Tile] # Available tiles

var player: Player
func _ready():
	player = Globals.get_matching_node(Player)
	to_collapse = 10
	
var to_collapse = 0
var collapse_distance = 20
func _process(delta: float) -> void:
	# Just for fun, lets grow it out slowly
	if to_collapse > 0:
		collapse_around_target(Vector3.ZERO, 10)
		to_collapse -= 10
	
	# For now, perform sensing here, but could optimize
	if player:
		var closest_slot = find_lowest_entropy_slot()
		var pgp = player.global_position
		if closest_slot and pgp.distance_to(closest_slot.global_position) < collapse_distance:
			to_collapse = 10
			

var edges_to_collapse: Array[TileSlot]
var backtrace_count = 0
var recently_collapsed: Array[TileSlot]  # For backtracing
var num_to_collapse = 0
func collapse_around_target(target_position: Vector3, num_tiles: int):
	# Initialize starting point
	# TODO want the cube of x tiles around the starting point
	# TODO or just the x/z square, ignoring y?
	edges_to_collapse.push_front(WorldTiles.get_slot(target_position))
	recently_collapsed = []
	
	# Collapse around target for num_tiles
	print("Starting collapse around %s"%[target_position])
	num_to_collapse = num_tiles
	while num_to_collapse > 0:
		# Find the next slot with the lowest entropy
		var slot = find_lowest_entropy_slot()
		
		# TODO DUPLICATING
		while find_lowest_entropy_slot() == null and backtrace_count < 10:
			backtrace(recently_collapsed)
		if backtrace_count >= 10:
			# TODO for debugging, let me look around
			print("Too much backtaracing %s"%backtrace_count)
			break
		
		# Collapse it
		var result = slot.collapse()
		match result:
			"collapsed":
				num_to_collapse -= 1
				# Add neighbors to collapse list
				var neighbors = slot.get_neighbors()
				edges_to_collapse.append_array(neighbors)
				for n in neighbors:
					n.update_constraints()
				recently_collapsed.push_front(slot)
			"already":
				edges_to_collapse.append_array(slot.get_neighbors())
				recently_collapsed.push_front(slot)
			"failed":
				backtrace(recently_collapsed)
				
		# If we ran out of slots, backtrace
		while find_lowest_entropy_slot() == null and backtrace_count < 10:
			backtrace(recently_collapsed)
		if backtrace_count >= 10:
			# TODO for debugging, let me look around
			print("Too much backtaracing %s"%backtrace_count)
			break
		
	print("Finished collapsing %s/%s"%[num_tiles-num_to_collapse, num_tiles])

func find_lowest_entropy_slot() -> TileSlot:
	# Pick the slot with the lowest entropy (fewest remaining valid tiles)
	edges_to_collapse = edges_to_collapse.filter(func(s): return !s.is_collapsed())
	
	# Sort by proximity to player, or entropy if there isn't one
	if player:
		var pgp = player.global_position
		edges_to_collapse.sort_custom(func(a, b):
			return pgp.distance_to(a.global_position) < pgp.distance_to(b.global_position)
		)
	else:
		edges_to_collapse.sort_custom(func(a, b): return a.get_entropy() < b.get_entropy())	
	
	if edges_to_collapse.size() == 0:
		return null
	return edges_to_collapse[0]

func backtrace(to_undo: Array[TileSlot]):
	# Reset tiles to a previous valid state if an impossible configuration is found
	# (e.g., remove the collapsed tiles and try another configuration)
	for ts in to_undo:
		ts.undo()
	print("Backtraced %s tiles"%to_undo.size())
	num_to_collapse += recently_collapsed.size()
	edges_to_collapse = recently_collapsed + edges_to_collapse
	recently_collapsed = []
	backtrace_count += 1
	
func _input(event):
	# Debug testing functions
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C:
			to_collapse += 10
