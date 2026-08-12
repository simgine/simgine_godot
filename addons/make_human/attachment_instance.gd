@tool
class_name MHAttachmentInstance
extends MeshInstance3D

@export var attachment: MHAttachment:
	set = set_attachment

@export_tool_button("Rebuild mesh", "BoxMesh") var rebuild_mesh_action := rebuild_mesh


func _enter_tree() -> void:
	rebuild_mesh()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if get_parent() is not MHInstance:
		warnings.append("MHAttachmentInstance must be a child of MHInstance.")

	return warnings


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		# Hide entirely since it is constructed dynamically.
		property.usage = PROPERTY_USAGE_NONE


func set_attachment(value: MHAttachment) -> void:
	if attachment == value:
		return

	if attachment:
		attachment.changed.disconnect(rebuild_mesh)

	attachment = value

	if attachment:
		attachment.changed.connect(rebuild_mesh)

	rebuild_mesh()


func rebuild_mesh() -> void:
	var body := get_parent() as MHInstance
	if not body or not body.morphed_vertices or not attachment or not attachment.geometry:
		mesh = null
		return

	var array_mesh := mesh as ArrayMesh
	if not array_mesh:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh

	var arrays := attachment.build_surface(body.morphed_vertices)

	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_name(0, attachment.name)

	if attachment.material:
		array_mesh.surface_set_material(0, attachment.material)
