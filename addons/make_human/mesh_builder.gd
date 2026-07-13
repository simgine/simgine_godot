class_name MakeHumanMeshBuilder

var _targets: Array[MakeHumanTarget.Meta]
## All MakeHuman base mesh vertices: body + helper geometry.
##
## Needed for morphs and clothes.
var _obj_vertices: PackedVector3Array
## OBJ vertex index -> array of render mesh vertex indices.
var _obj_to_render: Array[PackedInt32Array]


func build_body(mesh_data: MakeHumanMeshData, targets: Array[MakeHumanTarget.Meta]) -> ArrayMesh:
	_targets = targets
	_obj_vertices = mesh_data.vertices
	_obj_to_render.resize(mesh_data.vertices.size())
	for vertices in _obj_to_render:
		vertices.clear()

	var mesh = ArrayMesh.new()
	var arrays := _build_surface(mesh_data)

	var blend_shapes := []
	for target_meta in _targets:
		var shape_vertices := PackedVector3Array()
		shape_vertices.resize(arrays[Mesh.ARRAY_VERTEX].size())

		for i in target_meta.target.vertex_indices.size():
			var vertex_index = target_meta.target.vertex_indices[i]
			if vertex_index >= _obj_to_render.size():
				continue
			for render_vertex_index in _obj_to_render[vertex_index]:
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


func _build_surface(mesh_data: MakeHumanMeshData) -> Array:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for quad in mesh_data.quads:
		assert(quad.vertex_indices.size() == 4)

		var corners := PackedInt32Array()
		corners.resize(4)

		var p0 := mesh_data.vertices[quad.vertex_indices[0]]
		var p1 := mesh_data.vertices[quad.vertex_indices[1]]
		var p2 := mesh_data.vertices[quad.vertex_indices[2]]
		var normal := (p1 - p0).cross(p2 - p0).normalized()

		for corner_index in range(4):
			var vertex_index := quad.vertex_indices[corner_index]
			var uv_index := quad.uv_indices[corner_index]
			var render_vertex_index := vertices.size()

			corners[corner_index] = render_vertex_index
			vertices.append(mesh_data.vertices[vertex_index])
			uvs.append(mesh_data.uvs[uv_index])
			normals.append(normal)
			_obj_to_render[vertex_index].append(render_vertex_index)

		# Convert the quad into 2 triangles.
		indices.append(corners[0])
		indices.append(corners[2])
		indices.append(corners[1])

		indices.append(corners[0])
		indices.append(corners[3])
		indices.append(corners[2])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays
