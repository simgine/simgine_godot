@tool
class_name MHInstance
extends MeshInstance3D

const TARGET_PREFIX: String = "targets/"

@export var base_geometry: MHGeometry:
	set = set_base_geometry
@export var target_metadata: MHTargetMetadata:
	set = set_target_metadata

@export_tool_button("Rebuild meshes", "BoxMesh") var rebuild_mesh := _rebuild_mesh

var target_values: Dictionary[String, float]


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		# Hide entirely since it is constructed dynamically.
		property.usage = PROPERTY_USAGE_NONE


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	if target_metadata == null:
		return properties

	for section in target_metadata.sections:
		for category in section.categories:
			_add_category(properties, section, category)

	return properties


func _get(property: StringName) -> Variant:
	if property.begins_with(TARGET_PREFIX):
		var target_name := property.trim_prefix(TARGET_PREFIX)
		return target_values.get(target_name)

	return null


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with(TARGET_PREFIX):
		var target_name := property.trim_prefix(TARGET_PREFIX)
		set_target(target_name, value)
		return true

	return false


func set_base_geometry(value: MHGeometry) -> void:
	if base_geometry == value:
		return

	base_geometry = value

	target_values.clear()
	_rebuild_mesh()


func set_target_metadata(value: MHTargetMetadata) -> void:
	if target_metadata == value:
		return

	target_metadata = value

	target_values.clear()
	_rebuild_mesh()

	notify_property_list_changed()


func set_target(target_name: StringName, value: float) -> void:
	var clamped := clampf(value, -1.0, 1.0)
	if is_zero_approx(clamped):
		target_values.erase(target_name)
	else:
		target_values[target_name] = clamped
	_rebuild_mesh()


func _add_category(
	properties: Array[Dictionary],
	section: MHTargetSection,
	category: MHTargetCategory,
) -> void:
	var path := "%s/%s" % [section.label, category.name]

	if category.has_left_and_right:
		properties.append(_slider(path + "/left"))
		properties.append(_slider(path + "/right"))
	else:
		properties.append(_slider(path))


func _slider(path: String) -> Dictionary:
	return {
		"name": TARGET_PREFIX + path,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "-1.0,1.0,0.01",
		"usage": PROPERTY_USAGE_EDITOR,
	}


func _rebuild_mesh() -> void:
	if base_geometry == null:
		mesh = null
		return

	var vertices := _build_deformed_vertices()
	var arrays := _build_surface(base_geometry, vertices)

	if not mesh:
		mesh = ArrayMesh.new()
	mesh.clear_surfaces()

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_name(0, "Body")


func _build_deformed_vertices() -> PackedVector3Array:
	var vertices := base_geometry.vertices.duplicate()

	if target_metadata == null:
		return vertices

	for section in target_metadata.sections:
		for category in section.categories:
			_apply_category(vertices, section, category)

	return vertices


func _apply_category(
	vertices: PackedVector3Array,
	section: MHTargetSection,
	category: MHTargetCategory,
) -> void:
	if category.opposites == null:
		return

	var path := "%s/%s" % [section.label, category.name]

	if category.has_left_and_right:
		_apply_signed_targets(
			vertices,
			target_values.get(path + "/left", 0.0),
			category.opposites.negative_left,
			category.opposites.positive_left,
		)

		_apply_signed_targets(
			vertices,
			target_values.get(path + "/right", 0.0),
			category.opposites.negative_right,
			category.opposites.positive_right,
		)
	else:
		_apply_signed_targets(
			vertices,
			target_values.get(path, 0.0),
			category.opposites.negative_unsided,
			category.opposites.positive_unsided,
		)


func _apply_signed_targets(
	vertices: PackedVector3Array,
	value: float,
	negative_target: MHTarget,
	positive_target: MHTarget,
) -> void:
	if value < 0.0:
		_apply_target(vertices, negative_target, -value)
	elif value > 0.0:
		_apply_target(vertices, positive_target, value)


func _apply_target(vertices: PackedVector3Array, target: MHTarget, weight: float) -> void:
	if target == null:
		return

	assert(target.vertex_indices.size() == target.offsets.size())
	for index in target.vertex_indices.size():
		var vertex_index := target.vertex_indices[index]
		if vertex_index < vertices.size():
			vertices[vertex_index] += target.offsets[index] * weight


func _build_surface(geometry: MHGeometry, vertices: PackedVector3Array) -> Array:
	assert(vertices.size() == geometry.vertices.size())

	var topology := geometry.get_render_topology()
	var geometry_normals := _generate_smooth_normals(vertices, geometry.quads)

	var render_vertices := PackedVector3Array()
	render_vertices.resize(topology.vertex_count())

	var render_normals := PackedVector3Array()
	render_normals.resize(topology.vertex_count())

	for render_index in topology.vertex_count():
		var geometry_index := topology.geometry_indices[render_index]

		render_vertices[render_index] = vertices[geometry_index]
		render_normals[render_index] = geometry_normals[geometry_index]

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	arrays[Mesh.ARRAY_VERTEX] = render_vertices
	arrays[Mesh.ARRAY_NORMAL] = render_normals
	arrays[Mesh.ARRAY_TEX_UV] = topology.uvs
	arrays[Mesh.ARRAY_INDEX] = topology.indices

	return arrays


func _generate_smooth_normals(
	vertices: PackedVector3Array,
	quads: Array[MHQuad],
) -> PackedVector3Array:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())

	for quad: MHQuad in quads:
		var i0 := quad.vertex_indices[0]
		var i1 := quad.vertex_indices[1]
		var i2 := quad.vertex_indices[2]
		var i3 := quad.vertex_indices[3]

		# Use the opposite winding from the render indices to produce
		# outward-facing normals.

		# Triangle 1: 0, 1, 2.
		var normal_1 := (vertices[i1] - vertices[i0]).cross(vertices[i2] - vertices[i0])
		normals[i0] += normal_1
		normals[i2] += normal_1
		normals[i1] += normal_1

		# Triangle 2: 0, 2, 3.
		var normal_2 := (vertices[i2] - vertices[i0]).cross(vertices[i3] - vertices[i0])
		normals[i0] += normal_2
		normals[i3] += normal_2
		normals[i2] += normal_2

	for index in normals.size():
		if normals[index].is_zero_approx():
			normals[index] = Vector3.UP
		else:
			normals[index] = normals[index].normalized()

	return normals
