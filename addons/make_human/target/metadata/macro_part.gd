@tool
class_name MHMacroPart
extends Resource

## Lower bound of this segment (exclusive).
@export var lowest: float

## Upper bound of this segment (exclusive).
@export var highest: float

## Component name at the lower end.
##
## Empty if there is no lower component.
@export var low: String

## Component name at the upper end.
##
## Empty if there is no upper component.
@export var high: String


func get_weights(value: float) -> PartWeights:
	assert(value >= 0 and value <= 1.0)
	assert(highest > lowest)

	var weights := PartWeights.new()
	weights.high = (value - lowest) / (highest - lowest)
	weights.low = 1.0 - weights.high

	return weights


class PartWeights:
	var high: float
	var low: float
