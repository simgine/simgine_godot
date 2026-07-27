class_name MHMacroTargetPart
extends Resource

## Lower bound of this segment (inclusive).
##
## Slightly below 0.0 (e.g. -0.01) at the start to handle precision.
@export var lowest: float

## Upper bound of this segment (inclusive).
##
## Slightly above 1.0 (e.g. 1.01) at the end.
@export var highest: float

## Target name applied at the lower end.
##
## Empty string if none.
@export var low: String

## Target name applied at the upper end.
##
## Empty string if none.
@export var high: String
