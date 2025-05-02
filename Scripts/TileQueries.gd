# res://Scripts/TileQueries.gd

extends Node
class_name TileQueries

# Queries the ray for a resource, returning a Dictionary with:
#  "resource": ResourceData
#  "cell":     Vector2i
#  "tilemap":  TileMapLayer
# Or an empty Dictionary if nothing valid.
static func get_resource_data_from_ray(ray: RayCast2D) -> Dictionary:
	var info: Dictionary = {}  # explicit Dictionary
	if not ray.is_colliding():
		return info

	var collider = ray.get_collider()

	if collider is TileMapLayer:
		var hit_pos: Vector2 = ray.get_collision_point() - ray.get_collision_normal() * 0.1
		var cell: Vector2i = collider.local_to_map(collider.to_local(hit_pos))
		var td: TileData = collider.get_cell_tile_data(cell)

		if td:
			var res_id = td.get_custom_data("resource_type")

			if typeof(res_id) == TYPE_STRING and res_id != "":
				var res: ResourceData = ResourceManager.get_resource(res_id)
				if res:
					# *** Correct bracket syntax below ***
					info["resource"] = res
					info["cell"]     = cell
					info["tilemap"]  = collider
	return info
