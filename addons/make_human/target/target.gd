class_name MakeHumanTarget
extends Resource
## A morph target (shape key) for the MakeHuman base mesh.
##
## Imported from `.target` files.

@export_storage var vertex_indices: PackedInt32Array
@export_storage var offsets: PackedVector3Array

## Helper to attach a file name.
class Meta:
	var path: String
	var target: MakeHumanTarget


	func _init(new_path: String, new_target: MakeHumanTarget) -> void:
		path = new_path
		target = new_target
