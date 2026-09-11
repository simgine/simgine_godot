@tool
class_name MHTargetRegistry
extends Resource
## Targets from `target.json`.
##
## Categorizes all individual morph targets by body region,
## with left/right flags and opposite-direction pairing.

## Value range for regular modifiers.
const RANGE := Vector2(0.0, 1.0)

## Value range for opposite modifiers.
const OPPOSITE_RANGE := Vector2(-1.0, 1.0)

## Default weight for all modifiers.
const DEFAULT_VALUE := 0.0

## Body sections.
@export var sections: Array[MHTargetSection]


func apply(vertices: PackedVector3Array, modifiers: Dictionary[StringName, float]) -> void:
	for section in sections:
		section.apply(vertices, modifiers)
