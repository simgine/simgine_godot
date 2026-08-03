class_name MHMacroJSONImporter
extends EditorImportPlugin
## Importer for `macro.json`.
##
## For details, see https://github.com/makehumancommunity/mpfb2/blob/master/docs/fileformats/target_metadata.md


func _get_importer_name() -> String:
	return "make_human.macro_json_importer"


func _get_visible_name() -> String:
	return "MakeHuman Macro JSON Importer"


func _get_recognized_extensions() -> PackedStringArray:
	return ["json"]


func _get_save_extension() -> String:
	return "res"


func _get_resource_type() -> String:
	return "Resource"


func _get_preset_name(_preset_index: int) -> String:
	return ""


func _get_import_options(_path: String, _preset_index: int) -> Array[Dictionary]:
	return []


func _import(
	source_file: String,
	save_path: String,
	_options: Dictionary,
	_platform_variants: Array,
	_gen_files: Array,
) -> Error:
	var string := FileAccess.get_file_as_string(source_file)
	if FileAccess.get_open_error() != OK:
		push_error(
			"Unable to open '%s': %s" % [source_file, error_string(FileAccess.get_open_error())]
		)
		return ERR_PARSE_ERROR

	var json := JSON.new()
	if json.parse(string) != OK:
		push_error(
			"Unable to parse: '%s' at line %d" % [json.get_error_message(), json.get_error_line()],
		)
		return ERR_PARSE_ERROR

	if json.data is not Dictionary:
		push_error("Root is not an object")
		return ERR_PARSE_ERROR

	var registry := _parse_registry(json.data)
	if not registry:
		return ERR_PARSE_ERROR

	return ResourceSaver.save(registry, "%s.%s" % [save_path, _get_save_extension()])


func _parse_registry(dict: Dictionary) -> MHMacroTargetRegistry:
	var registry := MHMacroTargetRegistry.new()

	var macrotargets: Dictionary = dict.macrotargets
	for name: String in macrotargets:
		registry.macrotargets[name] = _parse_target(macrotargets[name])

	var combinations: Dictionary = dict.combinations
	for name: String in combinations:
		registry.combinations[name] = combinations[name]

	return registry


func _parse_target(dict: Dictionary) -> MHMacroTarget:
	var target := MHMacroTarget.new()
	target.label = dict.label

	for part_dict: Dictionary in dict.parts:
		var part := _parse_target_part(part_dict)
		target.parts.push_back(part)

	return target


func _parse_target_part(dict: Dictionary) -> MHMacroTargetPart:
	var part := MHMacroTargetPart.new()
	part.lowest = dict.lowest
	part.highest = dict.highest
	part.low = dict.low
	part.high = dict.high
	return part
