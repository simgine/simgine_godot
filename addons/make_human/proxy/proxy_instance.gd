@tool
class_name MHProxyInstance
extends MeshInstance3D
## Runtime mesh instance generated from an [MHProxy].

signal proxy_changed

@export var proxy: MHProxy:
	set = set_proxy


func _ready() -> void:
	if get_parent() is not MHBodyInstance:
		rebuild()


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh" or property.name == "skin":
		# Constructed dynamically from the proxy geometry.
		property.usage &= ~PROPERTY_USAGE_STORAGE
		property.usage |= PROPERTY_USAGE_READ_ONLY


func set_proxy(value: MHProxy) -> void:
	if proxy == value:
		return

	proxy = value

	if is_node_ready():
		rebuild()

	proxy_changed.emit()


func rebuild() -> void:
	if not proxy or not proxy.geometry:
		mesh = null
		skin = null
		skeleton = NodePath()
		return

	var arrays: Array
	var body_instance := get_parent() as MHBodyInstance
	if body_instance:
		if not body_instance.morphed_vertices:
			mesh = null
			skin = null
			skeleton = NodePath()
			return

		var skinning := body_instance.body.get_proxy_skinning(proxy)
		arrays = proxy.build_fitted_surface(body_instance.morphed_vertices, skinning)
		if body_instance.skeleton_node:
			skin = body_instance.skin
			skeleton = get_path_to(body_instance.skeleton_node)
		else:
			skin = null
			skeleton = NodePath()
	else:
		arrays = proxy.geometry.build_surface()
		skin = null
		skeleton = NodePath()

	var array_mesh := mesh as ArrayMesh
	if not array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh

	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		arrays,
		[],
		{ },
		Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS,
	)
	array_mesh.surface_set_name(0, proxy.name)

	if proxy.material:
		array_mesh.surface_set_material(0, proxy.material)
