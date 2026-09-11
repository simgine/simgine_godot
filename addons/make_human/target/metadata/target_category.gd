@tool
class_name MHTargetCategory
extends Resource
## Category object from `target.json`.

## Display label for the UI.
@export var label: String

## If `true`, the category has separate left (`l-`) and right (`r-`) prefixed targets.
@export var has_left_and_right: bool

## Maps opposing directions to targets.
@export var opposites: MHTargetOpposites

## All targets in this category.
@export var targets: Dictionary[StringName, MHTarget]


func apply(vertices: PackedVector3Array, modifiers: Dictionary[StringName, float]) -> void:
	if opposites:
		if has_left_and_right:
			_apply_sided_category(vertices, modifiers)
		else:
			_apply_unsided_category(vertices, modifiers)
	else:
		_apply_simple_category(vertices, modifiers)


func _apply_simple_category(
	vertices: PackedVector3Array,
	modifiers: Dictionary[StringName, float],
) -> void:
	for target_name in targets:
		var weight: float = modifiers.get(target_name, MHTargetRegistry.DEFAULT_VALUE)
		weight = clampf(weight, MHTargetRegistry.RANGE.x, MHTargetRegistry.RANGE.y)
		var target := targets[target_name]
		target.apply(vertices, weight)


func _apply_sided_category(
	vertices: PackedVector3Array,
	modifiers: Dictionary[StringName, float],
) -> void:
	_apply_signed(
		vertices,
		opposites.negative_left,
		opposites.positive_left,
		modifiers.get(label + "/left", MHTargetRegistry.DEFAULT_VALUE),
	)
	_apply_signed(
		vertices,
		opposites.negative_right,
		opposites.positive_right,
		modifiers.get(label + "/right", MHTargetRegistry.DEFAULT_VALUE),
	)


func _apply_unsided_category(
	vertices: PackedVector3Array,
	modifiers: Dictionary[StringName, float],
) -> void:
	_apply_signed(
		vertices,
		opposites.negative_unsided,
		opposites.positive_unsided,
		modifiers.get(label, MHTargetRegistry.DEFAULT_VALUE),
	)


func _apply_signed(
	vertices: PackedVector3Array,
	negative_name: StringName,
	positive_name: StringName,
	value: float,
) -> void:
	value = clampf(value, MHTargetRegistry.OPPOSITE_RANGE.x, MHTargetRegistry.OPPOSITE_RANGE.y)
	var target_name := positive_name if value > 0.0 else negative_name
	var target := targets[target_name]
	target.apply(vertices, absf(value))
