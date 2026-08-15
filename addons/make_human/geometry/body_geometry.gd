@tool
class_name MHBodyGeometry
extends MHGeometry
## MakeHuman basemesh data imported from OBJ.
##
## A renderable [ArrayMesh] is constructed at runtime after
## applying morphs to the OBJ vertices.
##
## OBJ vertex indices are also used for fitting proxies, because
## proxy definitions refer to body OBJ vertices when reconstructing
## their own vertices.

## Vertex positions, including helper geometry.
##
## [member vertices] includes helper geometry to preserve the original OBJ
## vertex indices. Helper faces are excluded from [member quads] because they
## are not rendered. Since render topology is built from the quads, helper
## vertices are also excluded from the resulting render mesh.
@export_storage var vertices: PackedVector3Array

## Number of body vertices before helper geometry begins.
const BODY_VERTEX_COUNT := 13380


## Adjusts the delete mask so it doesn't hide partially masked quads.
##
## Since vertices are shared between quads, a masked vertex may also
## belong to a neighbor quad that shouldn't be hidden. Such boundary
## vertices should be removed from the mask. This matches the
## conservative masking in MPFB2.
func make_mask_conservative(delete_mask: PackedByteArray) -> void:
	assert(delete_mask.size() == vertices.size())

	# We can't zero vertices immediately because they may belong to
	# other quads that still need to be checked.
	# This special value marks them for zeroing later.
	const REMOVE := 2

	for quad in quads:
		var masked_count := 0

		for vertex_index in quad.vertex_indices:
			if delete_mask[vertex_index] != 0:
				masked_count += 1

		if masked_count > 0 and masked_count < quad.vertex_indices.size():
			# Partially affected quad.
			for vertex_index in quad.vertex_indices:
				if delete_mask[vertex_index] != 0:
					delete_mask[vertex_index] = REMOVE

	for vertex_index in delete_mask.size():
		if delete_mask[vertex_index] == REMOVE:
			delete_mask[vertex_index] = 0


func build_masked_surface(
	morphed_vertices: PackedVector3Array,
	delete_mask: PackedByteArray,
) -> Array:
	assert(delete_mask.size() == vertices.size())
	assert(morphed_vertices.size() == vertices.size())

	var arrays := build_surface(morphed_vertices)
	arrays[Mesh.ARRAY_INDEX] = _filter_indices(delete_mask)
	return arrays


func _filter_indices(delete_mask: PackedByteArray) -> PackedInt32Array:
	var indices: PackedInt32Array
	for quad_index in quads.size():
		var quad := quads[quad_index]

		var deleted := false
		for vertex_index in quad.vertex_indices:
			if delete_mask[vertex_index]:
				deleted = true
				break

		if deleted:
			continue

		var offset := quad_index * 6
		for index in range(offset, offset + 6):
			indices.append(_topology.indices[index])

	return indices
