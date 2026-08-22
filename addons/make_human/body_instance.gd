@tool
class_name MHBodyInstance
extends MeshInstance3D

const MODIFIERS_PREFIX := "modifiers/"

@export_tool_button("Rebuild", "BoxMesh") var rebuild_action := _queue_rebuild.bind(Dirty.ALL)

@export var body_geometry: MHGeometry:
	set = set_body_geometry

@export var vertex_groups: MHVertexGroups:
	set = set_vertex_groups

@export var body_proxy: MHProxy:
	set = set_body_proxy

@export var target_registry: MHTargetRegistry:
	set = set_target_registry

@export var macro_registry: MHMacroRegistry:
	set = set_macro_registry

## Body shape modifier values.
@export_storage var _modifiers: Dictionary[StringName, float]

## Body vertices after applying the current modifier values.
##
## Stored to fit [member MHProxy.geometry] to the morphed body.
var morphed_vertices: PackedVector3Array

## Body vertices hidden by [MHProxyInstance] children.
var _body_mask: PackedByteArray

## Body vertices for [member body_proxy].
##
## Transferred to proxy geometry from [member _body_mask].
var _proxy_mask: PackedByteArray

enum Dirty {
	NONE = 0,
	GEOMETRY = 1 << 0,
	MASK = 1 << 1,
	ALL = GEOMETRY | MASK,
}

var _dirty: int = Dirty.NONE


func _init() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh" or property.name == "skin":
		# Constructed dynamically from the body geometry.
		property.usage &= ~PROPERTY_USAGE_STORAGE
		property.usage |= PROPERTY_USAGE_READ_ONLY


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	if not macro_registry or not target_registry:
		return properties

	for macro_name in macro_registry.macrotargets:
		properties.append(_slider(macro_name, 0.0, 1.0))

	for race in MHMacroRegistry.RACES:
		properties.append(_slider("race/" + race, 0.0, 1.0))

	for section in target_registry.sections:
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
		"name": MODIFIERS_PREFIX + path,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "%f,%f,0.01" % [minimum, maximum],
		"usage": PROPERTY_USAGE_EDITOR,
	}


func _get(property: StringName) -> Variant:
	if property.begins_with(MODIFIERS_PREFIX):
		var modifier_name := _property_to_modifier_name(property)
		return _modifiers.get(modifier_name, _get_default_modifier(modifier_name))

	return null


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with(MODIFIERS_PREFIX):
		var modifier_name := _property_to_modifier_name(property)
		set_modifier(modifier_name, value)
		return true

	return false


func _property_to_modifier_name(property: String) -> StringName:
	# Strips prefix and inspector group.
	var separator := property.find("/", MODIFIERS_PREFIX.length())
	if separator == -1:
		# Macro modifiers don't have an inspector group.
		return property.substr(MODIFIERS_PREFIX.length())
	return property.substr(separator + 1)


func set_body_geometry(value: MHGeometry) -> void:
	if body_geometry == value:
		return

	body_geometry = value
	_queue_rebuild(Dirty.ALL)


func set_body_proxy(value: MHProxy) -> void:
	if body_proxy == value:
		return

	if body_proxy:
		body_proxy.changed.disconnect(_queue_rebuild)

	body_proxy = value

	if body_proxy:
		body_proxy.changed.connect(_queue_rebuild.bind(Dirty.MASK))

	_queue_rebuild(Dirty.MASK)


func set_target_registry(value: MHTargetRegistry) -> void:
	if target_registry == value:
		return

	target_registry = value
	_queue_rebuild(Dirty.GEOMETRY)
	notify_property_list_changed()


func set_vertex_groups(value: MHVertexGroups) -> void:
	if vertex_groups == value:
		return

	vertex_groups = value
	_queue_rebuild(Dirty.GEOMETRY)


func set_macro_registry(value: MHMacroRegistry) -> void:
	if macro_registry == value:
		return

	macro_registry = value
	_queue_rebuild(Dirty.GEOMETRY)
	notify_property_list_changed()


func set_modifier(modifier_name: StringName, value: float) -> void:
	assert(macro_registry)
	assert(target_registry)

	var default := _get_default_modifier(modifier_name)

	if is_equal_approx(value, default):
		_modifiers.erase(modifier_name)
	else:
		_modifiers[modifier_name] = value

	_queue_rebuild(Dirty.GEOMETRY)


func _get_default_modifier(modifier_name: StringName) -> float:
	if macro_registry.macrotargets.has(modifier_name):
		return MHMacroRegistry.DEFAULT_MODIFIER

	if modifier_name in MHMacroRegistry.RACES:
		return MHMacroRegistry.DEFAULT_RACE_MODIFIER

	return MHTargetRegistry.DEFAULT_MODIFIER


func _on_child_entered_tree(child: Node) -> void:
	var instance := child as MHProxyInstance
	if not instance:
		return

	instance.proxy_changed.connect(_queue_rebuild.bind(Dirty.MASK))
	_queue_rebuild(Dirty.MASK)


func _on_child_exiting_tree(child: Node) -> void:
	var instance := child as MHProxyInstance
	if not instance:
		return

	instance.proxy_changed.disconnect(_queue_rebuild)
	_queue_rebuild(Dirty.MASK)


## Schedules a deferred rebuild, combining multiple changes into a single update.
func _queue_rebuild(dirty: Dirty) -> void:
	if _dirty == Dirty.NONE:
		# Rebuild only if it wasn't queued.
		_rebuild.call_deferred()

	_dirty |= dirty


func _rebuild() -> void:
	if not body_geometry or not vertex_groups or not target_registry or not macro_registry:
		mesh = null
		return

	if _dirty & Dirty.GEOMETRY:
		_rebuild_morphed_vertices()

	if _dirty & Dirty.MASK:
		_rebuild_mask()

	_rebuild_surface()

	if _dirty & Dirty.GEOMETRY:
		_rebuild_proxies()

	_dirty = Dirty.NONE


func _rebuild_morphed_vertices() -> void:
	morphed_vertices.clear()
	morphed_vertices.append_array(body_geometry.vertices)

	macro_registry.apply(morphed_vertices, _modifiers)
	target_registry.apply(morphed_vertices, _modifiers)
	_move_to_ground()


func _move_to_ground() -> void:
	var lowest_y := INF

	# Exclude helper geometry when calculating the lowest point.
	var body_vertices := vertex_groups.ranges["body"]
	assert(body_vertices.size() == 2, "body should have a single continuous range")
	for vertex_index in range(body_vertices[0], body_vertices[1] + 1):
		lowest_y = minf(lowest_y, morphed_vertices[vertex_index].y)

	# Move all geometry, including helpers since they affect proxies.
	for vertex_index in morphed_vertices.size():
		morphed_vertices[vertex_index].y -= lowest_y


func _rebuild_mask() -> void:
	_body_mask.resize(body_geometry.vertices.size())
	_body_mask.fill(0)

	for child in get_children():
		var instance := child as MHProxyInstance
		if not instance or not instance.proxy:
			continue

		instance.proxy.apply_delete_verts(_body_mask)

	body_geometry.make_mask_conservative(_body_mask)

	if body_proxy:
		body_proxy.transfer_delete_mask(_body_mask, _proxy_mask)


func _rebuild_surface() -> void:
	var array_mesh := mesh as ArrayMesh
	if not array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh

	var arrays: Array
	if body_proxy:
		arrays = body_proxy.build_masked_surface(_proxy_mask, morphed_vertices)
	else:
		arrays = body_geometry.build_masked_surface(_body_mask, morphed_vertices)

	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_name(0, "Body")


func _rebuild_proxies() -> void:
	for child in get_children():
		var instance := child as MHProxyInstance
		if instance:
			instance.rebuild_mesh()
