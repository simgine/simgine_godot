class_name MHMacroRegistry
extends Resource
## Macro targets from `macro.json`.
##
## Defines macro-level attributes (gender, age, weight, etc.)
## with interpolation ranges.

## Maps macro attribute names to their definitions.
@export var macrotargets: Dictionary[String, MHMacro]

## Maps combination names to arrays of macro attribute names.
##
## These define which macrotargets are combined to generate compound targets.
@export var combinations: Dictionary[String, PackedStringArray]
