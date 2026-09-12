class_name BodyModifier
extends Resource
## A body shape modifier from a [CharacterVisual].

## Referenced modifier name.
@export var name: StringName

## Display name for the character editor.
@export var display_name: String

## Editor label that describes the effect of decreasing the value.
@export var min_label: String

## Like [member min_label], but for the effect of increasing the value.
@export var max_label: String

## Display category for the character editor.
@export var category: ModifierCategory
