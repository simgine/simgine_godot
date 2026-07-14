class_name MakeHumanMeshBuilder

var _targets: Array[MakeHumanTarget.Meta]
## All base body mesh vertices: body + helper geometry.
##
## Needed for morphs and clothes.
var _body_vertices: PackedVector3Array
## Base body mesh vertex index -> multiple render mesh vertex indices.
var _body_to_mesh: Array[PackedInt32Array]


func build_body(geometry: MakeHumanGeometry, targets: Array[MakeHumanTarget.Meta]) -> ArrayMesh:
	_targets = targets
	_body_vertices = geometry.vertices
	_body_to_mesh.resize(geometry.vertices.size())
	for vertices in _body_to_mesh:
		vertices.clear()

	var mesh = ArrayMesh.new()
	var arrays := _build_arrays(geometry)

	var blend_shapes := []
	for target_meta in _targets:
		var shape_vertices := PackedVector3Array()
		shape_vertices.resize(arrays[Mesh.ARRAY_VERTEX].size())

		for i in target_meta.target.vertex_indices.size():
			var vertex_index = target_meta.target.vertex_indices[i]
			if vertex_index >= _body_to_mesh.size():
				continue
			for render_vertex_index in _body_to_mesh[vertex_index]:
				shape_vertices[render_vertex_index] = target_meta.target.offsets[i]

		var shape = []
		shape.resize(Mesh.ARRAY_MAX)
		shape[Mesh.ARRAY_VERTEX] = shape_vertices
		shape[Mesh.ARRAY_NORMAL] = arrays[Mesh.ARRAY_NORMAL]

		blend_shapes.append(shape)
		mesh.add_blend_shape(target_meta.path.get_file().get_basename())

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, blend_shapes)
	mesh.surface_set_name(0, "Body")

	return mesh


func _build_arrays(geometry: MakeHumanGeometry) -> Array:
	var mesh_vertices := PackedVector3Array()
	var mesh_uvs := PackedVector2Array()
	var mesh_normals := PackedVector3Array()
	var mesh_indices := PackedInt32Array()
	for quad in geometry.quads:
		var corners := PackedInt32Array()
		corners.resize(4)

		var p0 := geometry.vertices[quad.vertex_indices[0]]
		var p1 := geometry.vertices[quad.vertex_indices[1]]
		var p2 := geometry.vertices[quad.vertex_indices[2]]
		var normal := (p1 - p0).cross(p2 - p0).normalized()

		for corner_index in range(4):
			var vertex_index := quad.vertex_indices[corner_index]
			var uv_index := quad.uv_indices[corner_index]
			var mesh_vertex_index := mesh_vertices.size()

			corners[corner_index] = mesh_vertex_index
			mesh_vertices.append(geometry.vertices[vertex_index])
			mesh_uvs.append(geometry.uvs[uv_index])
			mesh_normals.append(normal)
			_body_to_mesh[vertex_index].append(mesh_vertex_index)

		# Convert the quad into 2 triangles.
		mesh_indices.append(corners[0])
		mesh_indices.append(corners[2])
		mesh_indices.append(corners[1])

		mesh_indices.append(corners[0])
		mesh_indices.append(corners[3])
		mesh_indices.append(corners[2])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = mesh_vertices
	arrays[Mesh.ARRAY_NORMAL] = mesh_normals
	arrays[Mesh.ARRAY_TEX_UV] = mesh_uvs
	arrays[Mesh.ARRAY_INDEX] = mesh_indices
	return arrays
