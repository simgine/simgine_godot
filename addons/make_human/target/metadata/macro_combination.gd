class_name MHMacroCombination
extends Resource
## A compound MakeHuman target family.
##
## Each entry in [member parts] contributes one component to the compound
## target name. Component weights are multiplied to determine the final target
## weight, except for dimensions listed in [member weight_exclusions].

## Internal identifier from the combinations object in macro.json.
@export var name: StringName

## Ordered macro dimensions used to build compound target names.
@export var parts: PackedStringArray

## Dimensions that contribute to the target name but not to its weight.
@export var weight_exclusions: PackedStringArray

## Optional restrictions on which components may be used for a dimension.
##
## For example, a combination may use only the `female` gender component.
@export var allowed_components: Dictionary[StringName, PackedStringArray]

## Maps compound component names to their target resources.
##
## For example:
## `female-young-averagemuscle-averageweight-minheight` -> MHTarget.
@export var targets: Dictionary[StringName, MHTarget]
