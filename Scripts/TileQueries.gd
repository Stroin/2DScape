# res://Scripts/TileQueries.gd
extends Node
class_name TileQueries

# --- public helpers -----------------------------------------------------

## Returns the resource_type string if the ray hit a resource-tile, else `""`.
static func check_resource_from_ray(ray: RayCast2D) -> String:
	if not ray.is_colliding():
		return ""
	var collider = ray.get_collider()
	if collider is TileMapLayer:
		var hit_pos : Vector2 = ray.get_collision_point() - ray.get_collision_normal() * 0.1
		var cell    : Vector2i = collider.local_to_map(collider.to_local(hit_pos))
		var td      : TileData = collider.get_cell_tile_data(cell)
		if td:
			var res_id = td.get_custom_data("resource_type")
			if typeof(res_id) == TYPE_STRING and res_id != "":
				print("Resource detected:", res_id, "at cell", cell)
				return res_id
	return ""

## Gathers the resource at world_pos if any. Returns `true` if gathered.
static func gather_resource(tilemap: TileMapLayer, world_pos: Vector2) -> bool:
	# world_pos is in global coords, convert to tilemap-local then to cell
	var cell : Vector2i = tilemap.local_to_map(tilemap.to_local(world_pos))
	var td   : TileData = tilemap.get_cell_tile_data(cell)
	if td:
		var res_id = td.get_custom_data("resource_type")
		if typeof(res_id) == TYPE_STRING and res_id != "":
			var res = ResourceManager.get_resource(res_id)
			if res:
				# simulate gather time
				print("Gathering %s..." % res.display_name)
				var tree = Engine.get_main_loop() as SceneTree
				var timer = tree.create_timer(res.gather_time)
				await timer.timeout
				# remove the tile
				tilemap.erase_cell(cell)
				print("%s gathered!" % res.display_name)
				# spawn drop
				if res.drop_scene:
					var drop = res.drop_scene.instantiate()
					var global_cell_pos = tilemap.to_global(tilemap.map_to_local(cell))
					drop.global_position = global_cell_pos + Vector2.ONE * tilemap.tile_size * 0.5
					tilemap.get_parent().add_child(drop)
				return true
	return false
