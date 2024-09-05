# The Wave Function Collapse solver
extends Node3D
class_name Solver

var palette: Array[Tile] # Available tiles

func _ready():
	collapse_around_target(Vector3.ZERO, 1)

func collapse_around_target(target_position: Vector3, num_tiles: int):
	# Initialize starting point
	# TODO want the cube of x tiles around the starting point
	# TODO or just the x/z square, ignoring y?
	var slots_to_collapse: Array[TileSlot] = [WorldTiles.get_slot(target_position)]
	var recently_collapsed: Array[TileSlot]  # For backtracing
	
	# Collapse around target for num_tiles
	print("Starting collapse around %s"%[target_position])
	var num_to_collapse = num_tiles
	while slots_to_collapse.size() > 0 and num_to_collapse > 0:
		# Find the next slot with the lowest entropy
		var slot = find_lowest_entropy_slot(slots_to_collapse)
		
		# Collapse it
		var result = slot.collapse()
		match result:
			"collapsed":
				num_to_collapse -= 1
				# Add neighbors to collapse list
				var neighbors = slot.get_neighbors()
				slots_to_collapse.append_array(neighbors)
				for n in neighbors:
					n.update_constraints()
				recently_collapsed.push_front(slot)
			"already":
				slots_to_collapse.append_array(slot.get_neighbors())
			"failed":
				# TODO
				print("FAILED")
				break
				#backtrace(recently_collapsed)
				#slots_to_collapse = recently_collapsed
				#num_to_collapse = num_tiles
				#recently_collapsed = []
		
	print("Finished collapsing %s/%s"%[num_tiles-num_to_collapse, num_tiles])

func find_lowest_entropy_slot(slots: Array[TileSlot]) -> TileSlot:
	# Pick the slot with the lowest entropy (fewest remaining valid tiles)
	slots.filter(func(s): return !s.is_collapsed())
	slots.sort_custom(func(a, b): return a.get_entropy() > b.get_entropy())
	return slots[0]

func backtrace(to_undo: Array[TileSlot]):
	# Reset tiles to a previous valid state if an impossible configuration is found
	# (e.g., remove the collapsed tiles and try another configuration)
	
	for ts in to_undo:
		ts.undo()
	print("Backtraced %s tiles"%to_undo.size())
	
func _input(event):
	# Debug testing functions
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C:
			collapse_around_target(Vector3.ZERO, 1)
