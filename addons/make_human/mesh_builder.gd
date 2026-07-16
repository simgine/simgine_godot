class_name MakeHumanMeshBuilder

var _targets: Array[MakeHumanTarget.Meta]
## All base body mesh vertices: body + helper geometry.
##
## Needed for morphs and clothes.
var _body_vertices: PackedVector3Array
## Base body mesh vertex index -> multiple render mesh vertex indices.
var _body_to_mesh: Array[PackedInt32Array]


func build_body(geometry: MakeHumanGeometry, targets: Array[MakeHumanTarget.Meta]) -> ArrayMesh:
	var surface := _build_surface(geometry)

	_targets = targets
	_body_vertices = geometry.vertices
	_body_to_mesh = surface.geometry_to_mesh

	var mesh := ArrayMesh.new()
	mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED

	for target_meta in _targets:
		mesh.add_blend_shape(target_meta.path.get_file().get_basename())

	var blend_shapes := _build_body_blend_shapes(
		geometry,
		surface.arrays[Mesh.ARRAY_VERTEX].size(),
	)

	mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		surface.arrays,
		blend_shapes,
	)
	mesh.surface_set_name(0, "Body")

	return mesh


func build_attachment(attachment: MakeHumanAttachment) -> ArrayMesh:
	assert(not _body_vertices.is_empty(), "body mesh should be built before the attachments")

	var attachment_vertices := _fit_attachment_vertices(
		attachment,
		_body_vertices,
	)
	var surface := _build_surface(
		attachment.geometry,
		attachment_vertices,
	)

	var mesh := ArrayMesh.new()
	mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED

	for target_meta in _targets:
		mesh.add_blend_shape(
			target_meta.path.get_file().get_basename(),
		)

	var blend_shapes := _build_attachment_blend_shapes(
		attachment,
		surface.geometry_to_mesh,
		surface.arrays[Mesh.ARRAY_VERTEX].size(),
	)

	mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		surface.arrays,
		blend_shapes,
	)
	mesh.surface_set_name(0, attachment.name)

	return mesh


## Builds render surface arrays and records geometry to the surface vertices mapping.
##
## Uses [member MakeHumanGeometry.vertices] when [param vertices_override] is empty.
## Otherwise, [param vertices_override] provides the vertex positions.
##
## Separate positions are needed for attachments because their positions are
## reconstructed from body vertices rather than taken from their geometry.
func _build_surface(geometry: MakeHumanGeometry, vertices_override := PackedVector3Array()) -> SurfaceBuildData:
	var vertices := geometry.vertices if vertices_override.is_empty() else vertices_override

	var mesh_vertices := PackedVector3Array()
	var mesh_uvs := PackedVector2Array()
	var mesh_normals := PackedVector3Array()
	var mesh_indices := PackedInt32Array()
	var geometry_to_mesh: Array[PackedInt32Array] = []
	geometry_to_mesh.resize(vertices.size())

	var normals := _generate_smooth_normals(vertices, geometry.quads)
	for quad in geometry.quads:
		var corners := PackedInt32Array()
		corners.resize(4)

		for corner_index in range(4):
			var vertex_index := quad.vertex_indices[corner_index]
			var uv_index := quad.uv_indices[corner_index]
			var mesh_vertex_index := mesh_vertices.size()

			corners[corner_index] = mesh_vertex_index

			mesh_vertices.append(vertices[vertex_index])
			mesh_uvs.append(geometry.uvs[uv_index])
			mesh_normals.append(normals[vertex_index])

			geometry_to_mesh[vertex_index].append(mesh_vertex_index)

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

	var surface := SurfaceBuildData.new()
	surface.arrays = arrays
	surface.geometry_to_mesh = geometry_to_mesh

	return surface


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

		# Use the opposite winding from the render indices to produce
		# outward-facing normals.

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


func _build_body_blend_shapes(geometry: MakeHumanGeometry, vertex_count: int) -> Array:
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
		shape_vertices.resize(vertex_count)

		var shape_normals := PackedVector3Array()
		shape_normals.resize(vertex_count)

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


func _build_attachment_blend_shapes(
		attachment: MakeHumanAttachment,
		attachment_to_mesh: Array[PackedInt32Array],
		mesh_vertex_count: int,
) -> Array:
	var blend_shapes := []
	for target_meta in _targets:
		var deformed_body_vertices := _body_vertices.duplicate()

		for i in target_meta.target.vertex_indices.size():
			var body_vertex_index := target_meta.target.vertex_indices[i]
			if body_vertex_index >= deformed_body_vertices.size():
				continue

			deformed_body_vertices[body_vertex_index] += target_meta.target.offsets[i]

		var deformed_vertices := _fit_attachment_vertices(attachment, deformed_body_vertices)
		var deformed_normals := _generate_smooth_normals(deformed_vertices, attachment.geometry.quads)

		var shape_vertices := PackedVector3Array()
		shape_vertices.resize(mesh_vertex_count)

		var shape_normals := PackedVector3Array()
		shape_normals.resize(mesh_vertex_count)

		for vertex_index in attachment_to_mesh.size():
			for mesh_vertex_index in attachment_to_mesh[vertex_index]:
				shape_vertices[mesh_vertex_index] = deformed_vertices[vertex_index]
				shape_normals[mesh_vertex_index] = deformed_normals[vertex_index]

		var shape := []
		shape.resize(Mesh.ARRAY_MAX)
		shape[Mesh.ARRAY_VERTEX] = shape_vertices
		shape[Mesh.ARRAY_NORMAL] = shape_normals
		blend_shapes.append(shape)

	return blend_shapes


## Reconstructs the attachment vertex positions for the current body shape.
func _fit_attachment_vertices(
		attachment: MakeHumanAttachment,
		body_vertices: PackedVector3Array,
) -> PackedVector3Array:
	var vertex_count := attachment.ref_a.size()
	assert(attachment.ref_b.size() == vertex_count)
	assert(attachment.ref_c.size() == vertex_count)
	assert(attachment.weights.size() == vertex_count)
	assert(attachment.offsets.size() == vertex_count)
	assert(attachment.geometry.vertices.size() == vertex_count)

	var offset_scale := _get_attachment_offset_scale(
		attachment,
		body_vertices,
	)

	var vertices := PackedVector3Array()
	vertices.resize(vertex_count)

	for vertex_index in vertex_count:
		var ref_a := attachment.ref_a[vertex_index]
		var ref_b := attachment.ref_b[vertex_index]
		var ref_c := attachment.ref_c[vertex_index]
		var weights := attachment.weights[vertex_index]
		var offset := attachment.offsets[vertex_index]

		# Barycentric position relative to the referenced body vertices.
		var position := (
				body_vertices[ref_a] * weights.x
				+ body_vertices[ref_b] * weights.y
				+ body_vertices[ref_c] * weights.z
		)

		var scaled_offset := Vector3(
			offset.x * offset_scale.x,
			offset.y * offset_scale.y,
			offset.z * offset_scale.z,
		)

		vertices[vertex_index] = position + scaled_offset

	return vertices


func _get_attachment_offset_scale(
		attachment: MakeHumanAttachment,
		body_vertices: PackedVector3Array,
) -> Vector3:
	return Vector3(
		_get_attachment_axis_scale(
			attachment.x_scale,
			body_vertices,
			Vector3.AXIS_X,
		),
		_get_attachment_axis_scale(
			attachment.y_scale,
			body_vertices,
			Vector3.AXIS_Y,
		),
		_get_attachment_axis_scale(
			attachment.z_scale,
			body_vertices,
			Vector3.AXIS_Z,
		),
	)


func _get_attachment_axis_scale(
		scale: MakeHumanScale,
		body_vertices: PackedVector3Array,
		axis: int,
) -> float:
	assert(not is_zero_approx(scale.factor))
	var minimum := body_vertices[scale.min_vertex][axis]
	var maximum := body_vertices[scale.max_vertex][axis]
	return absf(maximum - minimum) / scale.factor


class SurfaceBuildData:
	## Arrays suitable for passing to [method ArrayMesh.add_surface_from_arrays].
	var arrays: Array

	## Geometry vertex index -> corresponding render vertex indices.
	var geometry_to_mesh: Array[PackedInt32Array]
