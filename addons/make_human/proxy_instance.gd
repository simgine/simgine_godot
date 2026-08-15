@tool
class_name MHProxyInstance
extends MeshInstance3D
## Runtime mesh instance generated from an [MHProxy].

signal proxy_changed

@export var proxy: MHProxy:
	set = set_proxy

@export_tool_button("Rebuild mesh", "BoxMesh") var rebuild_mesh_action := rebuild_mesh


func _enter_tree() -> void:
	rebuild_mesh()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if get_parent() is not MHInstance:
		warnings.append("MHProxyInstance must be a child of MHInstance.")

	return warnings


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		# Hide entirely since it is constructed dynamically.
		property.usage = PROPERTY_USAGE_NONE


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
	rebuild_mesh()
	proxy_changed.emit()


func rebuild_mesh() -> void:
	var body := get_parent() as MHInstance
	if not body or not body.morphed_vertices or not proxy or not proxy.geometry:
		mesh = null
		return

	var array_mesh := mesh as ArrayMesh
	if not array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh

	var arrays := proxy.build_surface(body.morphed_vertices)

	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_name(0, proxy.name)

	if proxy.material:
		array_mesh.surface_set_material(0, proxy.material)
