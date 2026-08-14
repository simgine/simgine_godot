@tool
class_name MHMacroCombination
extends Resource
## A compound MakeHuman target family.
##
## Each entry in [member dimensions] contributes one component to the compound
## target name. Component weights are multiplied to determine the final target
## weight, except for dimensions listed in [member weight_exclusions].

## Ordered macro dimensions used to build compound target names.
@export var dimensions: Array[StringName]

## Dimensions that contribute to the target name but not to its weight.
@export var weight_exclusions: Array[StringName]

## Optional restrictions on which components may be used for a dimension.
##
## For example, a combination may use only the `female` gender component.
@export var allowed_components: Dictionary[StringName, PackedStringArray]

## Maps compound component names to their target resources.
##
## For example:
## `female-young-averagemuscle-averageweight-minheight` -> [MHTarget].
@export var targets: Dictionary[String, MHTarget]


## Applies all matching compound targets to vertices.
##
## [param components] maps each macro dimension in [member dimensions] to its active
## components and weights. Every valid combination of those components is used
## to resolve a target in [member targets].
func apply(vertices: PackedVector3Array, components: Dictionary[StringName, Array]) -> void:
	var selected_components: PackedStringArray
	_apply_recursive(vertices, components, selected_components, 0, 1.0)


func _apply_recursive(
	vertices: PackedVector3Array,
	components: Dictionary[StringName, Array],
	selected_components: PackedStringArray,
	dim_index: int,
	weight: float,
) -> void:
	const CUTOFF := 0.01

	if dim_index == dimensions.size():
		if weight <= CUTOFF:
			return

		var target_name := "-".join(selected_components)
		var target: MHTarget = targets.get(target_name)
		if target:
			target.apply(vertices, weight)

		return

	var dim_name := dimensions[dim_index]
	var dim_components: Array = components.get(dim_name, [])
	var allowed: PackedStringArray = allowed_components.get(dim_name, [])
	var contributes_weight := not weight_exclusions.has(dim_name)

	for component: MHMacroRegistry.Component in dim_components:
		if not allowed.is_empty() and not allowed.has(component.name):
			continue

		var next_weight := weight
		if contributes_weight:
			next_weight *= component.weight

			if next_weight <= CUTOFF:
				continue

		selected_components.push_back(component.name)

		_apply_recursive(vertices, components, selected_components, dim_index + 1, next_weight)

		selected_components.remove_at(selected_components.size() - 1)
