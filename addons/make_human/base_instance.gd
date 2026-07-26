@tool
class_name MHBaseInstance
extends MeshInstance3D

@export var base: MHBase:
	set = _set_base


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		# Hide entirely since it is constructed dynamically.
		property.usage = PROPERTY_USAGE_NONE


func _set_base(value: MHBase) -> void:
	if base == value:
		return

	if base:
		base.changed.disconnect(_update_mesh)

	base = value

	if base:
		base.changed.connect(_update_mesh)

	_update_mesh()


func _update_mesh() -> void:
	mesh = base.get_mesh() if base else null
