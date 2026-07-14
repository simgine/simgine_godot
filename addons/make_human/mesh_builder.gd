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

	var mesh := ArrayMesh.new()
	mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	for target_meta in _targets:
		mesh.add_blend_shape(target_meta.path.get_file().get_basename())

	var arrays := _build_arrays(geometry)
	var blend_shapes := _build_blend_shapes(geometry, arrays[Mesh.ARRAY_VERTEX].size())

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, blend_shapes)
	mesh.surface_set_name(0, "Body")

	return mesh


func _build_arrays(geometry: MakeHumanGeometry) -> Array:
	var mesh_vertices := PackedVector3Array()
	var mesh_uvs := PackedVector2Array()
	var mesh_normals := PackedVector3Array()
	var mesh_indices := PackedInt32Array()

	var normals := _generate_smooth_normals(geometry.vertices, geometry.quads)
	for quad in geometry.quads:
		var corners := PackedInt32Array()
		corners.resize(4)

		for corner_index in range(4):
			var vertex_index := quad.vertex_indices[corner_index]
			var uv_index := quad.uv_indices[corner_index]
			var mesh_vertex_index := mesh_vertices.size()

			corners[corner_index] = mesh_vertex_index
			mesh_vertices.append(geometry.vertices[vertex_index])
			mesh_uvs.append(geometry.uvs[uv_index])
			mesh_normals.append(normals[vertex_index])
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


## Builds area-weighted smooth normals for the geometry vertices.
func _generate_smooth_normals(
		vertices: PackedVector3Array,
		quads: Array[MakeHumanQuad],
) -> PackedVector3Array:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())

	for quad in quads:
		var i0 := quad.vertex_indices[0]
		var i1 := quad.vertex_indices[1]
		var i2 := quad.vertex_indices[2]
		var i3 := quad.vertex_indices[3]

		# Triangle 1: 0, 1, 2.
		var normal_1 := (vertices[i1] - vertices[i0]).cross(
			vertices[i2] - vertices[i0],
		)
		normals[i0] += normal_1
		normals[i2] += normal_1
		normals[i1] += normal_1

		# Triangle 2: 0, 2, 3.
		var normal_2 := (vertices[i2] - vertices[i0]).cross(
			vertices[i3] - vertices[i0],
		)
		normals[i0] += normal_2
		normals[i3] += normal_2
		normals[i2] += normal_2

	for i in normals.size():
		if not normals[i].is_zero_approx():
			normals[i] = normals[i].normalized()
		else:
			normals[i] = Vector3.UP

	return normals


func _build_blend_shapes(geometry: MakeHumanGeometry, vertices_count: int) -> Array:
	var blend_shapes := []
	for target_meta in _targets:
		var deformed_vertices := geometry.vertices.duplicate()
		for i in target_meta.target.vertex_indices.size():
			var vertex_index := target_meta.target.vertex_indices[i]
			if vertex_index >= _body_to_mesh.size():
				continue

			deformed_vertices[vertex_index] += target_meta.target.offsets[i]

		var deformed_normals := _generate_smooth_normals(deformed_vertices, geometry.quads)

		var shape_vertices := PackedVector3Array()
		shape_vertices.resize(vertices_count)

		var shape_normals := PackedVector3Array()
		shape_normals.resize(vertices_count)

		for vertex_index in _body_to_mesh.size():
			for mesh_vertex_index in _body_to_mesh[vertex_index]:
				shape_normals[mesh_vertex_index] = deformed_normals[vertex_index]
				shape_vertices[mesh_vertex_index] = deformed_vertices[vertex_index]

		var shape := []
		shape.resize(Mesh.ARRAY_MAX)
		shape[Mesh.ARRAY_VERTEX] = shape_vertices
		shape[Mesh.ARRAY_NORMAL] = shape_normals

		blend_shapes.append(shape)

	return blend_shapes
