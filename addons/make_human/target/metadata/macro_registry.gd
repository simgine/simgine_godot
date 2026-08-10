@tool
class_name MHMacroRegistry
extends Resource
## MakeHuman macro modifier definitions and compound target combinations.
##
## Imported from `macro.json` with additional MPFB2-specific metadata.

## Races are not included in macro.json and are hardcoded in MPFB2.
##
## Unlike regular macro modifiers, each race component represents a modifier
## with an independent weight.
const RACES: Array[StringName] = ["african", "asian", "caucasian"]

## Default value for all [constant RACES] modifiers.
const DEFAULT_RACE_MODIFIER := 0.33

## Default value for scalar macro modifiers.
const DEFAULT_MODIFIER := 0.5

## Maps macro modifier names to their definitions.
@export var macrotargets: Dictionary[StringName, MHMacro]

## Define which modifiers are combined to generate compound targets.
@export var combinations: Array[MHMacroCombination]


func apply(vertices: PackedVector3Array, modifiers: Dictionary[StringName, float]) -> void:
	var components := _resolve_components(modifiers)
	for combination in combinations:
		combination.apply(vertices, components)


func _resolve_components(modifiers: Dictionary[StringName, float]) -> Dictionary[StringName, Array]:
	var components: Dictionary[StringName, Array] = { }
	for name in macrotargets:
		var macro := macrotargets[name]
		var value: float = modifiers.get(name, DEFAULT_MODIFIER)
		var part := macro.find_part(value)
		if not part:
			# Sometimes values cannot be mapped to a region.
			# For example, 0.5 should skip "proportions".
			continue

		var weights := part.get_weights(value)
		var macro_components: Array[Component]
		if part.low:
			macro_components.push_back(Component.new(part.low, weights.low))

		if part.high:
			macro_components.push_back(Component.new(part.high, weights.high))

		components[name] = macro_components

	var race_components: Array[Component] = []
	for race in RACES:
		var value: float = modifiers.get(race, DEFAULT_RACE_MODIFIER)
		race_components.push_back(Component.new(race, value))
	components["race"] = race_components

	return components


class Component:
	var name: String
	var weight: float


	func _init(p_name: String, p_weight: float) -> void:
		name = p_name
		weight = p_weight
