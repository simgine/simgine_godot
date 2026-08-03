class_name MHTargetSection
extends Resource
## Section object from `target.json`.

## Display name for the UI.
@export var label: String

## Whether this section is visible by default in the UI.
@export var include_per_default: bool

## List of deformation category objects.
@export var categories: Array[MHTargetCategory]

## Targets that don't fit into any auto-detected category
@export var unsorted: Array[MHTarget]
