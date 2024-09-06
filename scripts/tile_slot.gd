extends Node3D
class_name TileSlot

var possible_tiles: Array[Tile] = Palette.ALL # Tiles that can fit in this slot
var collapsed_tile: Tile = null # The final tile assigned to this slot

func get_entropy() -> int:
	return possible_tiles.size()
	
func get_boundry_neighbors():
	# Returns the boundry and neighbors of this TileSlot, 
	# as an array of tuples: [[boundry, neighbor], ...
	# (in the same order as boundries)
	# TODO for now, only returning neighbors on not-empty boundraies,
	# e.g., ignore neighbors that are behind a wall or floor or w/e
	var neighbors = Globals.BOUNDARIES.map(func(b):
		if collapsed_tile and collapsed_tile.get(b.var_name) == "":
			return null
		return [b, WorldTiles.get_slot(self.position + b.offset * 2)]
	)
	neighbors = neighbors.filter(func(n): return n)  # filter nulls
	return neighbors

func get_neighbors():
	# Returns the (only) the TileSlot neighbors
	return get_boundry_neighbors().map(func(bn): return bn[1])
	
func collapse() -> String:
	# Returns the 'state' as a string
	# TODO enum
	if is_collapsed():
		return "already"
	if possible_tiles.size() == 0:
		return "failed"
	collapsed_tile = possible_tiles.pick_random()
	possible_tiles.clear() # No other tile can be placed here after collapse
	
	# TODO do we need to seperate the prefab 'collapsed_tile'
	# from the actuall instatntiated child tile? For backtracing?
	var my_tile = collapsed_tile.duplicate()
	self.add_child(my_tile)
	my_tile.position = Vector3.ZERO
	return "collapsed"

func undo():
	# Undoes the collapse
	possible_tiles = Palette.ALL.duplicate()
	collapsed_tile = null
	for child in get_children():
		child.free()
	for n in get_neighbors():
		n.update_constraints()
	
func is_collapsed() -> bool:
	if collapsed_tile:
		return true
	return false

func update_constraints():
	# A neighbor of mine just collapsed, remove any invalid tiles from my
	# possibilities
	if collapsed_tile:
		return
	possible_tiles = possible_tiles.filter(func(tile):
		return is_compatable(tile)
	)
	
func is_compatable(tile: Tile) -> bool:
	# Return true if the proposed tile wouldn't interfere with any of
	# our neighbors existing collapsed tiles
	
	# List of parings for what boundry variable in this tile
	# would pair with what boundry in the neighbor
	for bn in get_boundry_neighbors():
		var boundry = bn[0]
		var neighbor = bn[1]
		if !neighbor.is_collapsed():
			continue
		var neighbor_tile = neighbor.collapsed_tile
		var my_side = tile.get(boundry.var_name)
		var neighbor_boundry = boundry.get_neighbor_boundry()
		var neighbor_side = neighbor_tile.get(neighbor_boundry.var_name)
		if my_side != neighbor_side:
			return false
	return true

func _to_string() -> String:
	var s = "Slot %s "%position
	if collapsed_tile:
		s += "(%s)"%collapsed_tile.name
	else:
		s += "(%s possibilities)"%self.get_entropy()
	return s
	
func _process(delta: float) -> void:
	#var label = get_node_or_null("stats") as Label3D
	#if label == null:
		#label = Label3D.new()
		#label.name = "stats"
		#add_child(label)
	#label.position = Vector3(0, .6, 0)
	#label.text = self._to_string()
	
	# TODO a little silly, but helpful
	if Engine.get_process_frames() % 10 != 0:
		return
	var possilbe_child = get_node_or_null("possible") as Tile
	if possilbe_child != null:
		possilbe_child.free()
		
	if possible_tiles.size() in [0, Palette.ALL.size()] or is_collapsed():
		return
		
	var pt = possible_tiles.pop_front()
	possible_tiles.push_back(pt)
	possilbe_child = pt.duplicate()
	self.add_child(possilbe_child)
	possilbe_child.name = "possible"
	possilbe_child.position = Vector3.ZERO
	var mi = Globals.static_get_matching_node(possilbe_child, MeshInstance3D) as MeshInstance3D
	var ghost_mat = load("res://ghost_tile.tres") as StandardMaterial3D
	mi.material_override = ghost_mat
	
