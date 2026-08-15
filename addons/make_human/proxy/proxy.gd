@tool
class_name MHProxy
extends Resource
## Definition of a MakeHuman proxy that is fitted to and deforms with the
## body mesh.
##
## Imported from `.proxy` and `.mhclo` files.

## Display name.
@export var name: String

## Name of the author.
@export var author: String

## License under which the asset is distributed.
@export var license: String

## Human-readable description.
@export var description: String

## Search and classification tags.
@export var tags: PackedStringArray

## Source geometry loaded from the referenced OBJ file.
##
## Defines the proxy topology, UVs, and vertex ordering.
## But its vertex positions are ignored. Instead, each proxy
## vertex position is reconstructed from the body using the fitting data in
## this resource.
@export var geometry: MHGeometry

## Material loaded from the referenced `.mhmat` file.
@export var material: MHMaterial

## Defines how offsets are scaled along the X axis as the body
## changes shape.
##
## The scale is calculated from the distance between two selected body
## vertices relative to the reference distance from the proxy.
@export var x_scale: MHScale

## Like [member x_scale], but for Y axis.
@export var y_scale: MHScale

## Like [member x_scale], but for Z axis.
@export var z_scale: MHScale

## Stacking depth used to determine the order relative to the
## body and other proxies.
##
## Higher values generally represent outer layers, such as coats or
## backpacks, while lower values represent layers closer to the body.
@export var z_depth: int

## First body vertex reference for each proxy source vertex.
##
## Together with [member ref_b] and [member ref_c], this identifies the three
## body vertices from which a proxy vertex's fitted position is calculated.
##
## Must have one element for each proxy vertex.
@export_storage var ref_a: PackedInt32Array

## Second body vertex reference for each proxy source vertex.
@export_storage var ref_b: PackedInt32Array

## Third body vertex reference for each proxy source vertex.
@export_storage var ref_c: PackedInt32Array

## Three interpolation weights for each proxy source vertex.
##
## The X, Y, and Z components correspond to [member ref_a],
## [member ref_b], and [member ref_c], respectively. They define a weighted
## point relative to the three referenced body vertices.
@export_storage var weights: PackedVector3Array

## Local offset applied to each proxy source vertex after calculating
## its weighted body position.
##
## Each component is adjusted using [member x_scale], [member y_scale], or
## [member z_scale] before being added to the weighted position.
@export_storage var offsets: PackedVector3Array

## Inclusive ranges of body-mesh vertices hidden by this proxy.
##
## Stored as consecutive start/end pairs:
## `[start_0, end_0, start_1, end_1, ...]`.
##
## A single vertex is represented as a range whose start and end are equal.
@export_storage var delete_verts: PackedInt32Array


func apply_delete_verts(mask: PackedByteArray) -> void:
	assert(delete_verts.size() % 2 == 0, "should be stored as range pairs")
	for range_index in range(0, delete_verts.size(), 2):
		var first := delete_verts[range_index]
		var last := delete_verts[range_index + 1]
		assert(first >= 0)
		assert(last >= first)

		for vertex_index in range(first, last + 1):
			mask[vertex_index] = 1


func build_surface(body_vertices: PackedVector3Array) -> Array:
	var proxy_vertices := _fit_vertices(body_vertices)
	return geometry.build_surface(proxy_vertices)


## Reconstructs proxy vertex positions for the given body vertices.
func _fit_vertices(body_vertices: PackedVector3Array) -> PackedVector3Array:
	var vertex_count := ref_a.size()
	assert(ref_b.size() == vertex_count)
	assert(ref_c.size() == vertex_count)
	assert(weights.size() == vertex_count)
	assert(offsets.size() == vertex_count)

	var offset_scale := _calculate_offset_scale(body_vertices)

	var vertices: PackedVector3Array
	vertices.resize(vertex_count)

	for vertex_index in vertex_count:
		var body_a := body_vertices[ref_a[vertex_index]]
		var body_b := body_vertices[ref_b[vertex_index]]
		var body_c := body_vertices[ref_c[vertex_index]]
		var weight := weights[vertex_index]
		var offset := offsets[vertex_index]

		# Barycentric position relative to the referenced body vertices.
		var weighted_a := body_a * weight.x
		var weighted_b := body_b * weight.y
		var weighted_c := body_c * weight.z
		var weighted_position := weighted_a + weighted_b + weighted_c

		var scaled_offset := Vector3(
			offset.x * offset_scale.x,
			offset.y * offset_scale.y,
			offset.z * offset_scale.z,
		)

		vertices[vertex_index] = weighted_position + scaled_offset

	return vertices


func _calculate_offset_scale(body_vertices: PackedVector3Array) -> Vector3:
	return Vector3(
		x_scale.calculate(body_vertices, Vector3.AXIS_X),
		y_scale.calculate(body_vertices, Vector3.AXIS_Y),
		z_scale.calculate(body_vertices, Vector3.AXIS_Z),
	)
