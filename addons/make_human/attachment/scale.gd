class_name MakeHumanScale
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
