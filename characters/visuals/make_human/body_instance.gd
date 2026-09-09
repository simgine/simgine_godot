@tool
class_name MakeHumanBody
extends MHBodyInstance


func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)

	# Managed by by LookItem with skin slot.
	if property.name == "material_override":
		property.usage &= ~PROPERTY_USAGE_STORAGE
		property.usage |= PROPERTY_USAGE_READ_ONLY
