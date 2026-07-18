@tool
class_name MakeHumanInstance
extends MeshInstance3D

@export_tool_button("Rebuild mesh", "BoxMesh") var rebuild_topology = _rebuild_topology


func _init() -> void:
	if not mesh:
		_rebuild_topology()


func _validate_property(property: Dictionary) -> void:
	if property.name == "mesh":
		# Hide entirely since it's constructed dynamically.
		property.usage = PROPERTY_USAGE_NONE


func _rebuild_topology() -> void:
	var base := ResourceLoader.load("res://characters/human/assets/3dobjs/base.obj") as MakeHumanGeometry
	if not base:
		push_error("unable to load base mesh")
		return

	var targets := _load_targets()

	var builder := MakeHumanMeshBuilder.new()
	mesh = builder.build_body(base, targets)


func _load_targets() -> Array[MakeHumanTarget]:
	var dir = "res://characters/human/data/targets/"
	var targets: Array[MakeHumanTarget]
	var resources := ResourceLoader.list_directory(dir)
	for path in resources:
		if path.get_extension() == "target":
			var target := ResourceLoader.load(dir.path_join(path)) as MakeHumanTarget
			if target != null:
				targets.push_back(target)
			else:
				push_error("unable to load %s" % path)

	return targets
