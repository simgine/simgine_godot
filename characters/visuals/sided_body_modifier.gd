@tool
class_name SidedBodyModifier
extends BodyModifier
## A body modifier with independently adjustable left and right values.

## Suffix used to reference the left-side value.
@export var left_suffix: StringName

## Suffix used to reference the right-side value.
@export var right_suffix: StringName
