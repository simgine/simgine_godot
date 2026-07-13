class_name MakeHumanMhcloImporter
extends EditorImportPlugin
## Importer for MakeHuman `.mhclo` files.
##
## For details, see https://github.com/makehumancommunity/mpfb2/blob/master/docs/fileformats/mhclo.md

## Affects parsing for lines with unknown tag.
##
## Some files include tags even after `verts 0`, see:
## https://github.com/makehumancommunity/mpfb2/issues/409
##
## To make our parser compatible, we try to parse regular
## tags first and fallback to vertex parsing.
enum Section {
	NONE,
	VERTS,
	DELETE_VERTS,
}


func _get_importer_name() -> String:
	return "make_human.mhclo_importer"


func _get_visible_name() -> String:
	return "MakeHuman Attachment Importer"


func _get_recognized_extensions() -> PackedStringArray:
	return ["mhclo"]


func _get_save_extension() -> String:
	return "res"


func _get_resource_type() -> String:
	return "Resource"


func _get_preset_name(_preset_index: int) -> String:
	return ""


func _get_import_options(_path: String, _preset_index: int) -> Array[Dictionary]:
	return []


func _import(source_file: String, save_path: String, _options: Dictionary, _platform_variants: Array, _gen_files: Array) -> Error:
	var file := FileAccess.open(source_file, FileAccess.READ)
	if not file:
		push_error("Unable to open '%s': %s" % [source_file, error_string(FileAccess.get_open_error())])
		return ERR_PARSE_ERROR

	var section := Section.NONE
	var base_dir := source_file.get_base_dir()
	var attachment := MakeHumanAttachment.new()
	var line_index := 0
	while not file.eof_reached():
		line_index += 1

		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue

		if line.begins_with("#"):
			_parse_comment_meta(line, attachment)
			continue

		var tag := ""
		var value := line
		var separator := line.find(" ")
		if separator != -1:
			tag = line.substr(0, separator)
			value = line.substr(separator + 1).strip_edges()

		match tag:
			"basemesh":
				if value != "hm08":
					push_error("Unsupported basemesh at %d: '%s'" % [line_index, value])
					return ERR_PARSE_ERROR
			"name":
				attachment.name = value
			"tag":
				attachment.tags.push_back(value)
			"uuid":
				pass
			"obj_file":
				var path = base_dir.path_join(value)
				var geometry := ResourceLoader.load(path, "MakeHumanGeometry") as MakeHumanGeometry
				if geometry != null:
					attachment.geometry = geometry
				else:
					push_error("Could not load mesh data '%s' at %d" % [path, line_index])
			"material":
				var path = base_dir.path_join(value)
				var material := ResourceLoader.load(path, "MakeHumanMaterial") as MakeHumanMaterial
				if material != null:
					attachment.material = material
				else:
					push_error("Could not load material '%s' at %d" % [path, line_index])
			"x_scale":
				var scale := _parse_scale(value, line_index)
				if scale:
					attachment.x_scale = scale
			"y_scale":
				var scale := _parse_scale(value, line_index)
				if scale:
					attachment.y_scale = scale
			"z_scale":
				var scale := _parse_scale(value, line_index)
				if scale:
					attachment.z_scale = scale
			"z_depth":
				attachment.z_depth = value.to_int()
			"max_pole":
				pass
			"verts":
				if value != "0":
					push_error("Unsupported verts start at %d: '%s'" % [line_index, value])
					continue

				section = Section.VERTS
			"delete_verts":
				section = Section.DELETE_VERTS
			_:
				match section:
					Section.NONE:
						push_error("Unknown tag at %d: '%s'" % [line_index, line])
					Section.VERTS:
						if not _parse_vertex_mapping(line, attachment):
							push_error("Unknown vertex mapping at %d: '%s'" % [line_index, line])
					Section.DELETE_VERTS:
						# Not supported yet.
						pass
				continue

	return ResourceSaver.save(attachment, "%s.%s" % [save_path, _get_save_extension()])


func _parse_comment_meta(line: String, attachment: MakeHumanAttachment):
	var comment := line.substr(1).strip_edges()
	var separator := comment.find(" ")
	if separator == -1:
		return

	var tag := comment.substr(0, separator)
	match tag:
		"author":
			attachment.author = comment.substr(separator + 1)
		"license":
			attachment.license = comment.substr(separator + 1)
		"description":
			attachment.description = comment.substr(separator + 1)
		_:
			pass


func _parse_scale(value: String, line_index: int) -> MakeHumanScale:
	var parts := value.split(" ", false)
	if parts.size() != 3:
		push_error("Invalid X scale at %d: '%s'" % [line_index, value])
		return null

	var scale := MakeHumanScale.new()
	scale.min_vertex = parts[0].to_int()
	scale.max_vertex = parts[1].to_int()
	scale.factor = parts[2].to_float()
	return scale


func _parse_vertex_mapping(
		line: String,
		attachment: MakeHumanAttachment,
) -> bool:
	var parts := line.split(" ", false)
	match parts.size():
		1:
			var index := parts[0].to_int()

			attachment.ref_a.append(index)
			attachment.ref_b.append(index)
			attachment.ref_c.append(index)
			attachment.weights.append(Vector3(1.0, 0.0, 0.0))
			attachment.offsets.append(Vector3.ZERO)
			return true
		9:
			attachment.ref_a.append(parts[0].to_int())
			attachment.ref_b.append(parts[1].to_int())
			attachment.ref_c.append(parts[2].to_int())

			attachment.weights.append(
				Vector3(
					parts[3].to_float(),
					parts[4].to_float(),
					parts[5].to_float(),
				),
			)

			attachment.offsets.append(
				Vector3(
					parts[6].to_float(),
					parts[7].to_float(),
					parts[8].to_float(),
				),
			)
			return true
		_:
			return false
