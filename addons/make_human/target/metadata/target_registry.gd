@tool
class_name MHTargetRegistry
extends Resource
## Targets from `target.json`.
##
## Categorizes all individual morph targets by body region,
## with left/right flags and opposite-direction pairing.

## Default weight for all modifiers.
const DEFAULT_MODIFIER := 0.0

## Body sections.
@export var sections: Array[MHTargetSection]


func apply(vertices: PackedVector3Array, modifiers: Dictionary[StringName, float]) -> void:
	for section in sections:
		section.apply(vertices, modifiers)
