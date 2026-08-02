@tool
class_name MHInstance
extends MeshInstance3D

const TARGET_PREFIX: String = "targets/"

var base_geometry: MHGeometry
var target_metadata: MHTargetMetadata

@export_tool_button("Rebuild meshes", "BoxMesh") var rebuild_mesh_action := _rebuild_mesh

var target_values: Dictionary[String, float]

## Geometry body vertices after applying the current target values.
##
## Stored to fit attachments geometry based on it.
var _morphed_vertices: PackedVector3Array


func _init() -> void:
	var base_obj: String = ProjectSettings.get_setting(MakeHumanPlugin.BASE_OBJ_SETTING)
	base_geometry = ResourceLoader.load(base_obj) as MHGeometry

	var target_json: String = ProjectSettings.get_setting(MakeHumanPlugin.TARGET_JSON_SETTING)
	target_metadata = ResourceLoader.load(target_json) as MHTargetMetadata


func _ready() -> void:
	_rebuild_mesh()
	_rebuild_attachments()


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		# Hide entirely since it is constructed dynamically.
		property.usage = PROPERTY_USAGE_NONE


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	if not target_metadata:
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


func set_target(target_name: StringName, value: float) -> void:
	var clamped := clampf(value, -1.0, 1.0)
	if is_zero_approx(clamped):
		target_values.erase(target_name)
	else:
		target_values[target_name] = clamped

	_rebuild_mesh()
	_rebuild_attachments()


func get_morphed_vertices() -> PackedVector3Array:
	return _morphed_vertices


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
	if not base_geometry:
		_morphed_vertices.clear()
		mesh = null
		return

	_morphed_vertices.clear()
	_morphed_vertices.append_array(base_geometry.vertices)

	if target_metadata:
		for section in target_metadata.sections:
			for category in section.categories:
				_apply_category(section, category)

	var array_mesh := mesh as ArrayMesh
	if not array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh

	var arrays := base_geometry.build_surface(_morphed_vertices)

	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_name(0, "Body")


func _apply_category(section: MHTargetSection, category: MHTargetCategory) -> void:
	if not category.opposites:
		return

	var path := "%s/%s" % [section.label, category.name]

	if category.has_left_and_right:
		_apply_signed_targets(
			target_values.get(path + "/left", 0.0),
			category.opposites.negative_left,
			category.opposites.positive_left,
		)

		_apply_signed_targets(
			target_values.get(path + "/right", 0.0),
			category.opposites.negative_right,
			category.opposites.positive_right,
		)
	else:
		_apply_signed_targets(
			target_values.get(path, 0.0),
			category.opposites.negative_unsided,
			category.opposites.positive_unsided,
		)


func _apply_signed_targets(
	value: float,
	negative_target: MHTarget,
	positive_target: MHTarget,
) -> void:
	if value < 0.0:
		_apply_target(negative_target, -value)
	elif value > 0.0:
		_apply_target(positive_target, value)


func _apply_target(target: MHTarget, weight: float) -> void:
	if not target:
		return

	assert(target.vertex_indices.size() == target.offsets.size())
	for index in target.vertex_indices.size():
		var vertex_index := target.vertex_indices[index]
		if vertex_index < _morphed_vertices.size():
			_morphed_vertices[vertex_index] += target.offsets[index] * weight


func _rebuild_attachments() -> void:
	for child in get_children():
		var attachment := child as MHAttachmentInstance
		if attachment:
			attachment.rebuild_mesh()
