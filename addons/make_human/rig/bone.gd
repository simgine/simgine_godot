@tool
class_name MHBone
extends Resource

## Bone name.
@export var name: StringName

## Parent index in [member MHRig.bones], or `-1` for a root bone.
##
## Resolved from the parent name in the rig JSON during import.
@export var parent_index := -1

## Position strategy for the bone head.
@export var head: MHRigPosition

## Position strategy for the bone tail.
@export var tail: MHRigPosition

## Bone roll in radians.
@export var roll: float
