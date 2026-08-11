@tool
class_name MHScale
extends Resource
## Defines how attachment offsets are scaled along one coordinate axis.
##
## The current body size along that axis is measured between two body
## vertices.

## Index of the first body vertex.
##
## Despite the name inherited from the `.mhclo` format, this does not
## necessarily identify the vertex with the smaller coordinate value.
@export var min_vertex: int

## Index of the second body vertex.
@export var max_vertex: int

## Values used to divide the distance between [member min_vertex] and [member max_vertex]
##
## Must not be zero.
@export var factor: float


## Calculates the attachment offset scale for the given body axis.
##
## Uses the current distance between [member min_vertex] and [member max_vertex]
## along [param axis], normalized by [member factor].
func calculate(body_vertices: PackedVector3Array, axis: int) -> float:
	assert(not is_zero_approx(factor))

	var minimum := body_vertices[min_vertex][axis]
	var maximum := body_vertices[max_vertex][axis]

	return absf(maximum - minimum) / factor
