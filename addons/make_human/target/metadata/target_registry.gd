@tool
class_name MHTargetRegistry
extends Resource
## Targets from `target.json`.
##
## Categorizes all individual morph targets by body region,
## with left/right flags and opposite-direction pairing.

## Body sections.
@export var sections: Array[MHTargetSection]


func apply(vertices: PackedVector3Array, modifiers: Dictionary[StringName, float]) -> void:
	for section in sections:
		section.apply(vertices, modifiers)
