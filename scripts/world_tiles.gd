# 3D dictionary holding all slots in the world
extends Node3D
var tile_slots: Dictionary = {}

func get_slot(pos: Vector3) -> TileSlot:
	# Use the position as a dictionary key, convert it to a tuple or a hashable format
	var ts = Globals.TILE_SIZE  # shorthand
	
	# Round the position to the nearest multiple of tile_size
	var key = Vector3(
		round(pos.x / ts) * ts,
		round(pos.y / ts) * ts,
		round(pos.z / ts) * ts
	)
	
	if not tile_slots.has(key):
		var new_slot = TileSlot.new()
		new_slot.position = key
		add_child(new_slot)
		
		# Initialize the new slot with all possible tiles from the palette
		new_slot.possible_tiles = Palette.ALL.duplicate()
		tile_slots[key] = new_slot
		
		#print("    Created new TileSlot: %s"%key)
	
	return tile_slots[key]
