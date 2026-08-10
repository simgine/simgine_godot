@tool
class_name MHMacro
extends Resource
## A scalar MakeHuman macro modifier definition.
##
## Resolves a modifier value into weighted macro components using
## interpolation [member parts].

## Display name.
@export var label: String

## Interpolation segments used to resolve modifier values into components.
@export var parts: Array[MHMacroPart]


## Returns all component names referenced by [member parts].
func get_components() -> PackedStringArray:
	var result: PackedStringArray

	assert(parts.front().low)
	result.push_back(parts.front().low)

	# Each `high` equals `low` in the next part.
	for part in parts:
		if not part.high.is_empty():
			result.push_back(part.high)

	return result


## Returns the interpolation part containing the modifier value.
func find_part(value: float) -> MHMacroPart:
	assert(value >= 0 and value <= 1.0)
	for part in parts:
		if value > part.lowest and value < part.highest:
			return part

	return null
