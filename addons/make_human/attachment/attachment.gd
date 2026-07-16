class_name MakeHumanAttachment
extends Resource
## Metadata and geometry for a mesh that is fitted to and deforms with the
## body mesh.
##
## Imported from `.mhclo` files.

## Display name of the attachment.
@export var name: String
## Name of the attachment's author.
@export var author: String
## License under which the attachment is distributed.
@export var license: String
## Human-readable description of the attachment.
@export var description: String
## Search and classification tags associated with the attachment.
@export var tags: PackedStringArray
## Source geometry loaded from the attachment's referenced OBJ file.
##
## Defines the attachment topology, UVs, and vertex ordering.
## But its vertex positions are ignored. Instead, each attachment
## vertex position is reconstructed from the body using the fitting data in
## this resource.
@export var geometry: MakeHumanGeometry
## Material loaded from the attachment's referenced `.mhmat` file.
@export var material: MakeHumanMaterial
## Defines how attachment offsets are scaled along the X axis as the body
## changes shape.
##
## The scale is calculated from the distance between two selected body
## vertices relative to the reference distance stored in the `.mhclo` file.
@export var x_scale: MakeHumanScale
## Like [member x_scale], but for Y axis.
@export var y_scale: MakeHumanScale
## Like [member x_scale], but for Z axis.
@export var z_scale: MakeHumanScale
## Stacking depth used to determine the attachment's order relative to the
## body and other attachments.
##
## Higher values generally represent outer layers, such as coats or
## backpacks, while lower values represent layers closer to the body.
@export var z_depth: int
## First body vertex reference for each attachment source vertex.
##
## Together with [member ref_b] and [member ref_c], this identifies the three
## body vertices from which an attachment vertex's fitted position is
## calculated.
##
## Must have the same number of elements as [member geometry]'s vertex array.
@export_storage var ref_a: PackedInt32Array
## Second body vertex reference for each attachment source vertex.
@export_storage var ref_b: PackedInt32Array
## Third body vertex reference for each attachment source vertex.
@export_storage var ref_c: PackedInt32Array
## Three interpolation weights for each attachment source vertex.
##
## The X, Y, and Z components correspond to [member ref_a],
## [member ref_b], and [member ref_c], respectively. They define a weighted
## point relative to the three referenced body vertices.
@export_storage var weights: PackedVector3Array
## Local offset applied to each attachment source vertex after calculating
## its weighted body position.
##
## Each component is adjusted using [member x_scale], [member y_scale], or
## [member z_scale] before being added to the weighted position.
@export_storage var offsets: PackedVector3Array
