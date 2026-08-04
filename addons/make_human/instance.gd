@tool
class_name MHInstance
extends MeshInstance3D

const TARGET_PREFIX: String = "targets/"

@export var base_geometry: MHGeometry:
	set = set_base_geometry
@export var target_registry: MHTargetRegistry:
	set = set_target_registry

@export_tool_button("Rebuild meshes", "BoxMesh") var rebuild_mesh_action := _rebuild_mesh

var target_values: Dictionary[StringName, float]

## Geometry body vertices after applying the current target values.
##
## Stored to fit attachments geometry based on it.
var _morphed_vertices: PackedVector3Array


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		# Hide entirely since it is constructed dynamically.
		property.usage = PROPERTY_USAGE_NONE


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	if not target_registry:
		return properties

	for section in target_registry.sections:
		for category in section.categories:
			_add_category(properties, section, category)

	return properties


func _get(property: StringName) -> Variant:
	if property.begins_with(TARGET_PREFIX):
		var target_name := _property_to_target_name(property)
		return target_values.get(target_name)

	return null


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with(TARGET_PREFIX):
		var target_name := _property_to_target_name(property)
		set_target(target_name, value)
		return true

	return false


func set_base_geometry(value: MHGeometry) -> void:
	if base_geometry == value:
		return

	base_geometry = value

	target_values.clear()
	_rebuild_mesh()
	_rebuild_attachments()


func set_target_registry(value: MHTargetRegistry) -> void:
	if target_registry == value:
		return

	target_registry = value

	target_values.clear()
	_rebuild_mesh()
	_rebuild_attachments()

	notify_property_list_changed()


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

	if category.opposites:
		if category.has_left_and_right:
			properties.append(_slider(path + "/left", -1.0, 1.0))
			properties.append(_slider(path + "/right", -1.0, 1.0))
		else:
			properties.append(_slider(path, -1.0, 1.0))
	else:
		properties.append(_slider(path, 0.0, 1.0))


func _slider(path: String, minimum: float, maximum: float) -> Dictionary:
	return {
		"name": TARGET_PREFIX + path,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "%f,%f,0.01" % [minimum, maximum],
		"usage": PROPERTY_USAGE_EDITOR,
	}


func _property_to_target_name(property: String) -> String:
	# Strips prefix and section name.
	var sep_pos := property.find("/", TARGET_PREFIX.length())
	assert(sep_pos != -1)
	return property.substr(sep_pos + 1)


func _rebuild_mesh() -> void:
	if not base_geometry:
		_morphed_vertices.clear()
		mesh = null
		return

	_morphed_vertices.clear()
	_morphed_vertices.append_array(base_geometry.vertices)

	if target_registry:
		target_registry.apply(_morphed_vertices, target_values)

	var array_mesh := mesh as ArrayMesh
	if not array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh

	var arrays := base_geometry.build_surface(_morphed_vertices)

	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_name(0, "Body")


func _rebuild_attachments() -> void:
	for child in get_children():
		var attachment := child as MHAttachmentInstance
		if attachment:
			attachment.rebuild_mesh()
