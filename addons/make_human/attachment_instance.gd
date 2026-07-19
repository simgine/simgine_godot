@tool
class_name MakeHumanAttachmentInstance
extends MeshInstance3D

@export var base: MakeHumanBase:
	set = _set_base
@export var attachment: MakeHumanAttachment:
	set(value):
		if attachment != value:
			attachment = value
			_update_mesh()


func _ready() -> void:
	_update_mesh()


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		# Hide entirely since it's constructed dynamically.
		property.usage = PROPERTY_USAGE_NONE


func _set_base(value: MakeHumanBase) -> void:
	if base == value:
		return

	if base:
		base.changed.disconnect(_update_mesh)

	base = value

	if base:
		base.changed.connect(_update_mesh)

	_update_mesh()


func _update_mesh() -> void:
	if base and attachment:
		mesh = base.get_attachment_mesh(attachment)
		material_override = attachment.material
	else:
		mesh = null
		material_override = null
