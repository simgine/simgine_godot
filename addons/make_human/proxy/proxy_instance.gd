@tool
class_name MHProxyInstance
extends MeshInstance3D
## Runtime mesh instance generated from an [MHProxy].

signal proxy_changed

@export_tool_button("Rebuild mesh", "BoxMesh") var rebuild_mesh_action := rebuild_mesh

@export var proxy: MHProxy:
	set = set_proxy

var _skinning: MHSkinning


func _enter_tree() -> void:
	rebuild_skinning()
	rebuild_mesh()


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh" or property.name == "skin":
		# Constructed dynamically from the proxy geometry.
		property.usage &= ~PROPERTY_USAGE_STORAGE
		property.usage |= PROPERTY_USAGE_READ_ONLY


func set_proxy(value: MHProxy) -> void:
	if proxy == value:
		return

	if proxy:
		proxy.changed.disconnect(_on_proxy_changed)

	proxy = value

	if proxy:
		proxy.changed.connect(_on_proxy_changed)

	_on_proxy_changed()


func _on_proxy_changed() -> void:
	rebuild_skinning()
	rebuild_mesh()
	proxy_changed.emit()


func rebuild_skinning() -> void:
	_skinning = null
	skin = null
	skeleton = NodePath()

	var body := get_parent() as MHBodyInstance
	if not body or not proxy or not body.skinning:
		return

	_skinning = MHSkinning.new()
	_skinning.build_from_proxy(body.skinning, proxy)


func rebuild_mesh() -> void:
	if not proxy or not proxy.geometry:
		mesh = null
		return

	var body := get_parent() as MHBodyInstance
	var arrays: Array
	if body:
		if not body.morphed_vertices:
			mesh = null
			return

		arrays = proxy.build_surface(_skinning, body.morphed_vertices)
		if _skinning:
			skin = body.skin
			skeleton = get_path_to(body.skeleton_node)
		else:
			skin = null
			skeleton = NodePath()
	else:
		arrays = proxy.geometry.build_surface(_skinning)
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
