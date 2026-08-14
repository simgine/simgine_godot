@tool
class_name MHGeometry
extends Resource
## MakeHuman mesh data imported from OBJ.
##
## Used for attachments. Doesn't include vertices because they are
## dynamically reconstructed from [MHBodyGeometry] using MHCLO data
## after all morph targets are applied. A renderable [ArrayMesh] is
## constructed at runtime with [method build_surface].

## UV coordinates.
@export_storage var uvs: PackedVector2Array:
	set(value):
		uvs = value
		_topology = null

## Quad faces.
##
## In MakeHuman OBJ files all faces are represented as quads.
@export_storage var quads: Array[MHQuad]:
	set(value):
		quads = value
		_topology = null

## Cached data for [method build_surface].
var _topology: RenderTopology


## Creates a [ArrayMesh] surface based on the geometry vertices.
func build_surface(vertices: PackedVector3Array) -> Array:
	var geometry_normals := _generate_smooth_normals(vertices)

	if not _topology:
		_topology = RenderTopology.new()
		_build_render_topology()

	var vertex_count := _topology.geometry_indices.size()

	var render_vertices: PackedVector3Array
	render_vertices.resize(vertex_count)

	var render_normals: PackedVector3Array
	render_normals.resize(vertex_count)

	for render_index in vertex_count:
		var geometry_index := _topology.geometry_indices[render_index]

		render_vertices[render_index] = vertices[geometry_index]
		render_normals[render_index] = geometry_normals[geometry_index]

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	arrays[Mesh.ARRAY_VERTEX] = render_vertices
	arrays[Mesh.ARRAY_NORMAL] = render_normals
	arrays[Mesh.ARRAY_TEX_UV] = _topology.uvs
	arrays[Mesh.ARRAY_INDEX] = _topology.indices

	return arrays


func _generate_smooth_normals(morphed_vertices: PackedVector3Array) -> PackedVector3Array:
	var normals: PackedVector3Array
	normals.resize(morphed_vertices.size())

	for quad in quads:
		var i0 := quad.vertex_indices[0]
		var i1 := quad.vertex_indices[1]
		var i2 := quad.vertex_indices[2]
		var i3 := quad.vertex_indices[3]

		# Use the opposite winding from the render indices to produce
		# outward-facing normals.

		# Triangle 1: 0, 1, 2.
		var normal_1 := (morphed_vertices[i1] - morphed_vertices[i0]).cross(
			morphed_vertices[i2] - morphed_vertices[i0]
		)
		normals[i0] += normal_1
		normals[i2] += normal_1
		normals[i1] += normal_1

		# Triangle 2: 0, 2, 3.
		var normal_2 := (morphed_vertices[i2] - morphed_vertices[i0]).cross(
			morphed_vertices[i3] - morphed_vertices[i0]
		)
		normals[i0] += normal_2
		normals[i3] += normal_2
		normals[i2] += normal_2

	for index in normals.size():
		normals[index] = normals[index].normalized()

	return normals


## Builds and stores a render topology from UV and quad data.
##
## MakeHuman geometry uses separate indices for vertex positions and UV
## coordinates. Godot's [ArrayMesh], however, uses a single index for all
## vertex attributes.
##
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
## positions. It can therefore be built once and shared by every instance that
## uses the same [MHGeometry].
##
## Per-instance mesh rebuilding only needs to expand the current geometry
## positions and normals through [RenderTopology.geometry_indices]. UVs and triangle
## indices remain unchanged and are reused.
func _build_render_topology() -> void:
	var vertex_lookup: Dictionary[Vector2i, int]
	for quad in quads:
		var i0 := _get_or_create_vertex(vertex_lookup, quad.vertex_indices[0], quad.uv_indices[0])
		var i1 := _get_or_create_vertex(vertex_lookup, quad.vertex_indices[1], quad.uv_indices[1])
		var i2 := _get_or_create_vertex(vertex_lookup, quad.vertex_indices[2], quad.uv_indices[2])
		var i3 := _get_or_create_vertex(vertex_lookup, quad.vertex_indices[3], quad.uv_indices[3])

		# Convert the quad into two triangles.
		_topology.indices.append(i0)
		_topology.indices.append(i2)
		_topology.indices.append(i1)

		_topology.indices.append(i0)
		_topology.indices.append(i3)
		_topology.indices.append(i2)


func _get_or_create_vertex(
	vertex_lookup: Dictionary[Vector2i, int],
	geometry_index: int,
	uv_index: int,
) -> int:
	var key := Vector2i(geometry_index, uv_index)
	var existing_index: int = vertex_lookup.get(key, -1)

	if existing_index >= 0:
		return existing_index

	var render_index := _topology.geometry_indices.size()
	vertex_lookup[key] = render_index

	_topology.geometry_indices.append(geometry_index)
	_topology.uvs.append(uvs[uv_index])

	return render_index


class RenderTopology:
	## For each render vertex, stores the corresponding original geometry vertex.
	##
	## Several render vertices may reference the same geometry vertex when that
	## vertex lies on a UV seam.
	var geometry_indices: PackedInt32Array

	## One UV coordinate for every render vertex.
	var uvs: PackedVector2Array

	## Triangle indices referencing the compact render vertex arrays.
	var indices: PackedInt32Array
