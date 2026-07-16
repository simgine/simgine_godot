class_name MakeHumanGeometry
extends Resource
## Raw MakeHuman mesh data imported from OBJ.
##
## Unlike materials, a Godot ArrayMesh cannot be fully imported on its own,
## because blend shapes must be known when the mesh is constructed. Since
## `.target` files may be discovered at runtime (for example from mods), the
## final Godot mesh is built later from this raw representation.
##
## Keeping the original OBJ vertex indices is also important for fitting
## clothes and body parts, because MHCLO and targets refer to OBJ vertices,
## which are different from render mesh vertices (because they're duplicated).

@export_storage var vertices: PackedVector3Array
@export_storage var uvs: PackedVector2Array
@export_storage var quads: Array[MakeHumanQuad]
