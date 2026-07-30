class_name MHRenderTopology
## Builds and stores a compact render topology from [MHGeometry] UV and quad data.
##
## [MHGeometry] stores the original geometry topology used by MakeHuman targets:
## one position per geometry vertex, quad vertex indices, and separate UV indices.
## Morph targets modify these original geometry vertices.
##
## Godot's [ArrayMesh], however, uses a single index for all vertex attributes.
## A render vertex therefore represents an attribute combination:
## geometry vertex + UV coordinate.
##
## Adjacent faces can share the same render vertex when they use both the same
## geometry vertex and the same UV. If the geometry vertex lies on a UV seam,
## it is represented by multiple render vertices, one for each distinct UV.
##
## During construction, every quad corner is converted into a key with vertex and UV.
## Corners with an existing key reuse the previously created render vertex.
## Otherwise, a new render vertex is added. Quad corners are then converted
## into triangle indices referencing these compact render vertices.
##
## The topology depends only on face and UV structure, not on deformed vertex
## positions. It can therefore be built once and shared by every body, clothing
## item, or other instance that uses the same [MHGeometry].
##
## Per-instance mesh rebuilding only needs to expand the current geometry
## positions and normals through [member geometry_indices]. UVs and triangle
## indices remain unchanged and are reused.

## For each render vertex, stores the corresponding original geometry vertex.
##
## Several render vertices may reference the same geometry vertex when that
## vertex lies on a UV seam.
var geometry_indices := PackedInt32Array()

## One UV coordinate for every render vertex.
var uvs := PackedVector2Array()

## Triangle indices referencing the compact render vertex arrays.
var indices := PackedInt32Array()


func _init(geometry_uvs: PackedVector2Array, geometry_quads: Array[MHQuad]) -> void:
	var vertex_lookup: Dictionary[Vector2i, int]
	for quad in geometry_quads:
		var i0 := _get_or_create_vertex(
			vertex_lookup,
			geometry_uvs,
			quad.vertex_indices[0],
			quad.uv_indices[0],
		)
		var i1 := _get_or_create_vertex(
			vertex_lookup,
			geometry_uvs,
			quad.vertex_indices[1],
			quad.uv_indices[1],
		)
		var i2 := _get_or_create_vertex(
			vertex_lookup,
			geometry_uvs,
			quad.vertex_indices[2],
			quad.uv_indices[2],
		)
		var i3 := _get_or_create_vertex(
			vertex_lookup,
			geometry_uvs,
			quad.vertex_indices[3],
			quad.uv_indices[3],
		)

		# Convert the quad into two triangles.
		indices.append(i0)
		indices.append(i2)
		indices.append(i1)

		indices.append(i0)
		indices.append(i3)
		indices.append(i2)


func vertex_count() -> int:
	return geometry_indices.size()


func _get_or_create_vertex(
	vertex_lookup: Dictionary[Vector2i, int],
	geometry_uvs: PackedVector2Array,
	geometry_index: int,
	uv_index: int,
) -> int:
	var key := Vector2i(geometry_index, uv_index)
	var existing_index: int = vertex_lookup.get(key, -1)

	if existing_index >= 0:
		return existing_index

	var render_index := geometry_indices.size()
	vertex_lookup[key] = render_index

	geometry_indices.append(geometry_index)
	uvs.append(geometry_uvs[uv_index])

	return render_index
