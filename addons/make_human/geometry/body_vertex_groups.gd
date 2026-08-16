class_name MHVertexGroups
extends Resource
## Vertex group metadata.
##
## OBJ groups apply to faces, not to vertices.
## This provides additional metadata for the direct mapping.
##
## Imported from `basemesh_vertex_groups.json`.

## Maps vertex group names to their vertex index ranges.
##
## Each value is an array of `[start, end]` pairs (inclusive ranges).
## A group can have multiple non-contiguous ranges.
@export var ranges: Dictionary[StringName, PackedInt32Array]
