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
	if body == null or attachment == null or attachment.geometry == null:
		mesh = null
		return

	var body_vertices := body.get_morphed_vertices()
	if body_vertices.is_empty():
		mesh = null
		return

	var attachment_vertices := _fit_vertices(body_vertices)
	var arrays := attachment.geometry.build_surface(attachment_vertices)

	var array_mesh := mesh as ArrayMesh
	if array_mesh == null:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh

	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_name(
		0,
		attachment.name if not attachment.name.is_empty() else "Attachment",
	)

	if attachment.material:
		array_mesh.surface_set_material(0, attachment.material)


func _fit_vertices(body_vertices: PackedVector3Array) -> PackedVector3Array:
	var vertex_count := attachment.ref_a.size()

	assert(attachment.ref_b.size() == vertex_count)
	assert(attachment.ref_c.size() == vertex_count)
	assert(attachment.weights.size() == vertex_count)
	assert(attachment.offsets.size() == vertex_count)
	assert(
		attachment.geometry.vertices.size() == 0,
		"vertices derived from the body and the attachment data",
	)

	var offset_scale := _calculate_offset_scale(body_vertices)

	var vertices := PackedVector3Array()
	vertices.resize(vertex_count)

	for vertex_index in vertex_count:
		var ref_a := attachment.ref_a[vertex_index]
		var ref_b := attachment.ref_b[vertex_index]
		var ref_c := attachment.ref_c[vertex_index]
		var weights := attachment.weights[vertex_index]
		var offset := attachment.offsets[vertex_index]

		# Barycentric position relative to the referenced body vertices.
		var weighted_a := body_vertices[ref_a] * weights.x
		var weighted_b := body_vertices[ref_b] * weights.y
		var weighted_c := body_vertices[ref_c] * weights.z

		var weighted_position := weighted_a + weighted_b + weighted_c

		var scaled_offset := Vector3(
			offset.x * offset_scale.x,
			offset.y * offset_scale.y,
			offset.z * offset_scale.z,
		)

		vertices[vertex_index] = weighted_position + scaled_offset

	return vertices


func _calculate_offset_scale(body_vertices: PackedVector3Array) -> Vector3:
	return Vector3(
		_calculate_axis_scale(attachment.x_scale, body_vertices, Vector3.AXIS_X),
		_calculate_axis_scale(attachment.y_scale, body_vertices, Vector3.AXIS_Y),
		_calculate_axis_scale(attachment.z_scale, body_vertices, Vector3.AXIS_Z),
	)


func _calculate_axis_scale(
	scale_data: MHScale,
	body_vertices: PackedVector3Array,
	axis: int,
) -> float:
	assert(not is_zero_approx(scale_data.factor))

	var minimum := body_vertices[scale_data.min_vertex][axis]
	var maximum := body_vertices[scale_data.max_vertex][axis]

	return absf(maximum - minimum) / scale_data.factor
