@tool
class_name MHRigPosition
extends Resource
## Defines how bone endpoints are positioned relative to the base mesh.

## Position strategy.
##
## Not the full list, but the game engine rig uses only these strategies.
enum Strategy {
	## Positions the endpoint at the center of a joint cube defined by a vertex group on the base mesh.
	CUBE,
	## Positions the endpoint at a single mesh vertex.
	VERTEX,
	## Positions the endpoint at the average of two or more mesh vertices.
	MEAN,
}

@export var strategy: Strategy

## Joint cube vertex group name, e.g. "joint-spine-1".
##
## Used by `CUBE`.
@export var cube_name: StringName

## Vertex indices to average.
##
## Used by `VERTEX` (holds a single value) and `MEAN`.
@export var vertex_indices: PackedInt32Array
