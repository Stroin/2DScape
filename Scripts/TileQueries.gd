extends Node
class_name TileQueries

# --- public helpers -----------------------------------------------------

## Returns *true* if the ray hit a tile whose custom layer “is_tree” is true.
static func check_tree_from_ray(ray: RayCast2D) -> bool:
	if not ray.is_colliding():
		return false

	var collider := ray.get_collider()
	if collider is TileMapLayer:
		var hit_pos : Vector2  = ray.get_collision_point() - ray.get_collision_normal() * 0.1
		var cell    : Vector2i = collider.local_to_map(collider.to_local(hit_pos))
		var td      : TileData = collider.get_cell_tile_data(cell)

		if td and td.get_custom_data("is_tree"):
			print("Tree detected at cell ", cell)
			return true
	return false


## Removes the tile at *world_pos* if its “is_tree” flag is set.
## Returns *true* when a tree was successfully chopped.
static func chop_tree(tilemap: TileMapLayer, world_pos: Vector2) -> bool:
	var cell : Vector2i = tilemap.local_to_map(tilemap.to_local(world_pos))
	var td   : TileData = tilemap.get_cell_tile_data(cell)
	if td and td.get_custom_data("is_tree"):
		tilemap.erase_cell(cell)
		print("Tree chopped!")
		return true
	return false
