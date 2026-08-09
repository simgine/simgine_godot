@tool
class_name MHTargetSection
extends Resource
## Section object from `target.json`.

## Display name for the UI.
@export var label: String

## Whether this section is visible by default in the UI.
@export var include_per_default: bool

## List of deformation category objects.
@export var categories: Array[MHTargetCategory]


func apply(vertices: PackedVector3Array, modifiers: Dictionary[StringName, float]) -> void:
	for category in categories:
		category.apply(vertices, modifiers)
