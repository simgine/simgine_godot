@tool
class_name MHTargetRegistry
extends Resource
## Targets from `target.json`.
##
## Categorizes all individual morph targets by body region,
## with left/right flags and opposite-direction pairing.

## Body sections.
@export var sections: Array[MHTargetSection]


func apply(vertices: PackedVector3Array, values: Dictionary[StringName, float]) -> void:
	for section in sections:
		for category in section.categories:
			_apply_category(vertices, category, values)


func _apply_category(
	vertices: PackedVector3Array,
	category: MHTargetCategory,
	values: Dictionary[StringName, float],
) -> void:
	if category.opposites:
		if category.has_left_and_right:
			_apply_sided_category(vertices, category, values)
		else:
			_apply_unsided_category(vertices, category, values)
	else:
		_apply_simple_category(vertices, category, values)


func _apply_simple_category(
	vertices: PackedVector3Array,
	category: MHTargetCategory,
	values: Dictionary[StringName, float],
) -> void:
	for target_name in category.targets:
		var weight: float = values.get(target_name, 0.0)
		var target := category.targets[target_name]
		target.apply(vertices, weight)


func _apply_sided_category(
	vertices: PackedVector3Array,
	category: MHTargetCategory,
	values: Dictionary[StringName, float],
) -> void:
	_apply_signed(
		vertices,
		category.targets,
		category.opposites.negative_left,
		category.opposites.positive_left,
		values.get(category.name + "/left", 0.0),
	)
	_apply_signed(
		vertices,
		category.targets,
		category.opposites.negative_right,
		category.opposites.positive_right,
		values.get(category.name + "/right", 0.0),
	)


func _apply_unsided_category(
	vertices: PackedVector3Array,
	category: MHTargetCategory,
	values: Dictionary[StringName, float],
) -> void:
	_apply_signed(
		vertices,
		category.targets,
		category.opposites.negative_unsided,
		category.opposites.positive_unsided,
		values.get(category.name, 0.0),
	)


func _apply_signed(
	vertices: PackedVector3Array,
	targets: Dictionary[StringName, MHTarget],
	negative_name: StringName,
	positive_name: StringName,
	value: float,
) -> void:
	var target_name := positive_name if value > 0.0 else negative_name
	var target := targets[target_name]
	target.apply(vertices, absf(value))
