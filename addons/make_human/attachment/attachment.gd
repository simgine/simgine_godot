class_name MakeHumanAttachment
extends Resource
## Metadata about a mesh that is to be fitted to and deform with the basemesh.
##
## Imported from `.mhclo` files.

@export var name: String
@export var author: String
@export var license: String
@export var description: String
@export var tags: PackedStringArray
@export var geometry: MakeHumanGeometry
@export var material: MakeHumanMaterial
@export var x_scale: MakeHumanScale
@export var y_scale: MakeHumanScale
@export var z_scale: MakeHumanScale
@export var z_depth: int
@export_storage var ref_a: PackedInt32Array
@export_storage var ref_b: PackedInt32Array
@export_storage var ref_c: PackedInt32Array
@export_storage var weights: PackedVector3Array
@export_storage var offsets: PackedVector3Array
