extends Node3D
class_name Palette

# All 'prefabs' of possible tiles
static var ALL: Array[Tile] = []

func _ready() -> void:
	ALL = create_tiles()
	
func show_palette():
	# For now, lay out created tiles for debug viewing
	var palette_offset = Vector3(0, -8, 0)
	for t in ALL:
		add_child(t)
		t.position = palette_offset
		palette_offset += Vector3(0, -1, 0)
		if abs(palette_offset.y) > 20:
			palette_offset.y = -8
			palette_offset.z += 6

func filter_children(parent: Node, starts_with: String):
	return parent.get_children().filter(func(node):
		return node.name.begins_with(starts_with)
	)
	
func create_tiles() -> Array[Tile]:
	var blender_tile_info = get_node("tiles")
	var tile_nodes = filter_children(blender_tile_info, "tile")
	var bridge_nodes = filter_children(blender_tile_info, "bridge")
	
	var tiles: Array[Tile]
	for child in tile_nodes:
		if child.name.begins_with("tile"):
			tiles += create_tiles_from_blender(child, bridge_nodes)
			# We disable the origional node so its colliders and whatnot
			# don't interfere
			child.get_parent().remove_child(child)
	
	return tiles

func create_tiles_from_blender(blender_tile_node, bridge_nodes) -> Array[Tile]:
	# Given a mesh node from blender, use the surrounding objects
	# to tell what it's connections should be.
	
	# Create a new 'Tile' GDScript Node3D
	var tile = Tile.new()
	# copy a new instance of the blender_tile_node mesh node
	# as a child of 'tile
	var tile_mesh_instance = blender_tile_node.duplicate()
	tile.add_child(tile_mesh_instance)
	tile_mesh_instance.position = Vector3.ZERO
	tile.name = get_blender_node_name(blender_tile_node)
	assert(tile.name != "", blender_tile_node.name)
	
	for bridge in bridge_nodes:
		var b_name = get_blender_node_name(bridge)
		# if the bridge is at the +z of this blender_tile_node,
		# then we know that the Tiles z_plus connection name should be
		# the bridge's b_name
		# (etc for +z, -z, +x, -x, +y, -y)
		
		# Iterate through all bridge nodes to figure out the connections
		var bridge_pos = bridge.global_transform.origin
		var tile_pos = blender_tile_node.global_transform.origin
		var offset = Globals.TILE_SIZE / 2
		var tolerance = 0.1

		var distance = bridge_pos - tile_pos
		
		# if the bridge isn't close to this tile, ignore it
		if distance.length() > offset + tolerance:
			continue
		
		# Check x-, x+, z-, z+, y-, y+
		for boundry in Globals.BOUNDARIES:
			var near_offset = distance - boundry.offset
			if near_offset.length() < tolerance:
				tile.set(boundry.var_name, b_name)

	return tile.get_variants()
	
func get_blender_node_name(bridge_node) -> String:
	# Node name from blender will be something like:
	# bridge catwalk_001
	# - but we just want to return "catwalk"
	var parts = bridge_node.name.split(" ")
	if parts.size() > 1:
		return parts[1].split("_")[0]
	return ""
