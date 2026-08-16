@tool
class_name MHBone
extends Resource

## Parent bone name.
##
## Empty string for root bones.
@export var parent: StringName

## Position strategy for the bone head.
@export var head: MHRigPosition

## Position strategy for the bone tail.
@export var tail: MHRigPosition

## Bone roll in radians.
@export var roll: float
