@tool
class_name MHInstance
extends MeshInstance3D

const TARGETS_PREFIX: String = "targets/"

var _base_geometry: MHGeometry
var _target_registry: MHTargetRegistry

@export_tool_button("Rebuild meshes", "BoxMesh") var rebuild_mesh_action := _rebuild_mesh

var modifiers: Dictionary[StringName, float]

## Geometry body vertices after applying the current target values.
##
## Stored to fit attachments geometry based on it.
var _morphed_vertices: PackedVector3Array


func _init() -> void:
	var data_dir: String = ProjectSettings.get_setting(MakeHumanPlugin.DATA_DIR_SETTING)

	var base_obj := data_dir.path_join("3dobjs/base.obj")
	_base_geometry = ResourceLoader.load(base_obj)

	var target_json := data_dir.path_join("targets/target.json")
	_target_registry = ResourceLoader.load(target_json)


func _ready() -> void:
	_rebuild_mesh()
	_rebuild_attachments()


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		# Hide entirely since it is constructed dynamically.
		property.usage = PROPERTY_USAGE_NONE


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	for section in _target_registry.sections:
		for category in section.categories:
			_add_category(properties, section, category)

	return properties


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
		"name": TARGETS_PREFIX + path,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "%f,%f,0.01" % [minimum, maximum],
		"usage": PROPERTY_USAGE_EDITOR,
	}


func _get(property: StringName) -> Variant:
	if property.begins_with(TARGETS_PREFIX):
		var target_name := _property_to_target_name(property)
		return modifiers.get(target_name)

	return null


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with(TARGETS_PREFIX):
		var target_name := _property_to_target_name(property)
		set_modifier(target_name, value)
		return true

	return false


func _property_to_target_name(property: String) -> String:
	# Strips prefix and section name.
	var sep_pos := property.find("/", TARGETS_PREFIX.length())
	assert(sep_pos != -1)
	return property.substr(sep_pos + 1)


func set_modifier(target_name: StringName, value: float) -> void:
	var clamped := clampf(value, -1.0, 1.0)
	if is_zero_approx(clamped):
		modifiers.erase(target_name)
	else:
		modifiers[target_name] = clamped

	_rebuild_mesh()
	_rebuild_attachments()


func _rebuild_mesh() -> void:
	_morphed_vertices.clear()
	_morphed_vertices.append_array(_base_geometry.vertices)

	_target_registry.apply(_morphed_vertices, modifiers)

	var array_mesh := mesh as ArrayMesh
	if not array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh

	var arrays := _base_geometry.build_surface(_morphed_vertices)

	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_name(0, "Body")


func _rebuild_attachments() -> void:
	for child in get_children():
		var attachment := child as MHAttachmentInstance
		if attachment:
			attachment.rebuild_mesh()


func get_morphed_vertices() -> PackedVector3Array:
	return _morphed_vertices
