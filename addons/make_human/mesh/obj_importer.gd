class_name MakeHumanObjImporter
extends EditorImportPlugin
## Importer for MakeHuman `.obj` files.
##
## We can't use the built-in parser because we need to
## create mappings from OBJ vertices to the resulting
## mesh vertices in order to apply morphs and clothes.
##
## Supports only a subset of OBJ that is used in
## MakeHuman assets.


func _get_importer_name() -> String:
	return "make_human.obj_importer"


func _get_visible_name() -> String:
	return "MakeHuman OBJ Importer"


func _get_recognized_extensions() -> PackedStringArray:
	return ["obj"]


func _get_save_extension() -> String:
	return "res"


func _get_resource_type() -> String:
	return "Resource"


func _get_preset_name(_preset_index: int) -> String:
	return ""


func _get_import_options(_path: String, _preset_index: int) -> Array[Dictionary]:
	return [
		{
			"name": "included_groups",
			"default_value": PackedStringArray(),
		},
	]


func _import(source_file: String, save_path: String, options: Dictionary, _platform_variants: Array, _gen_files: Array) -> Error:
	var file := FileAccess.open(source_file, FileAccess.READ)
	if not file:
		push_error("Unable to open '%s': %s" % [source_file, error_string(FileAccess.get_open_error())])
		return ERR_PARSE_ERROR

	var included_groups: PackedStringArray = options["included_groups"]
	var geometry := MakeHumanGeometry.new()
	var line_index := 0
	var last_groups: PackedStringArray
	while not file.eof_reached():
		line_index += 1
		var line := file.get_line()
		line = line.get_slice("#", 0).strip_edges()

		var parts := line.split(" ", false)
		if parts.is_empty():
			continue

		var tag := parts[0]
		match tag:
			"v":
				if parts.size() != 4:
					push_error("Unsupported vertex at %d: '%s'" % [line_index, line])
					continue

				var x := parts[1].to_float()
				var y := parts[2].to_float()
				var z := parts[3].to_float()
				geometry.vertices.push_back(Vector3(x, y, z))
			"vt":
				if parts.size() != 3:
					push_error("Unsupported UV at %d: '%s'" % [line_index, line])
					continue

				var u := parts[1].to_float()
				var v := parts[2].to_float()
				geometry.uvs.append(Vector2(u, 1.0 - v)) # V should be flipped to match Godot.
			"vn":
				# Normals are ignored and will be generated automatically.
				pass
			"s":
				# Smooth shading always applied.
				pass
			"g":
				last_groups = parts.slice(1)
			"f":
				if not _include_vertices(last_groups, included_groups):
					continue
				if parts.size() != 5:
					push_error("Unsupported face at %d: '%s'" % [line_index, line])
					continue

				var quad = _parse_quad(parts, line_index)
				if quad:
					geometry.quads.push_back(quad)
			_:
				push_error("Unsupported tag at %d: '%s'" % [line_index, line])

	return ResourceSaver.save(geometry, "%s.%s" % [save_path, _get_save_extension()])


func _include_vertices(groups: PackedStringArray, included_groups: PackedStringArray) -> bool:
	if groups.is_empty() or included_groups.is_empty():
		return true

	for group in included_groups:
		if group in groups:
			return true

	return false


func _parse_quad(parts: PackedStringArray, line_index: int) -> MakeHumanQuad:
	var quad := MakeHumanQuad.new()
	for i in range(1, parts.size()):
		var corner = parts[i]
		var items := corner.split("/")
		if items.size() != 2:
			push_error("Unsupported corner at %d: '%s'" % [line_index, corner])
			return null

		# Indices are 1-based, convert to 0-based.
		quad.vertex_indices.push_back(items[0].to_int() - 1)
		quad.uv_indices.push_back(items[1].to_int() - 1)

	return quad
