@tool
class_name MHRig
extends Resource
## Defines the bone hierarchy and how each bone endpoint is
## positioned relative to the mesh.
##
## Imported from `rig.*.json`.

## Maps bone names to their definitions.
@export var bones: Dictionary[StringName, MHBone]
