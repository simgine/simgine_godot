class_name BodyModifierParams
extends RefCounted
## Associates a [BodyModifier] with value parameters from a [CharacterVisual].

## Associated modifier.
var modifier: BodyModifier

## Inclusive range of accepted values.
var value_range: Vector2

## Default modifier value.
var default_value: float


func _init(p_modifier: BodyModifier, p_value_range: Vector2, p_default_value: float) -> void:
	modifier = p_modifier
	value_range = p_value_range
	default_value = p_default_value
