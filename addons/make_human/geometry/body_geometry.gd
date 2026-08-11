@tool
class_name MHBodyGeometry
extends MHGeometry
## MakeHuman basemesh data imported from OBJ.
##
## A renderable [ArrayMesh] is constructed at runtime after
## applying morphs to the OBJ vertices.
##
## OBJ vertex indices are also used for fitting clothes and body
## parts, because MHCLO files refer to OBJ vertices in order to
## reconstruct their own.

## Vertex positions.
@export_storage var vertices: PackedVector3Array


func build_surface(morphed_vertices: PackedVector3Array) -> Array:
	assert(vertices.size() == morphed_vertices.size())
	return super(morphed_vertices)
