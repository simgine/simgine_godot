class_name MHTargetJSONImporter
extends EditorImportPlugin
## Importer for `target.json`.
##
## For details, see https://github.com/makehumancommunity/mpfb2/blob/master/docs/fileformats/target_metadata.md


func _get_importer_name() -> String:
	return "make_human.target_json_importer"


func _get_visible_name() -> String:
	return "MakeHuman Target JSON Importer"


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

	var base_dir := source_file.get_base_dir()
	var registry := _parse_registry(json.data, base_dir)

	return ResourceSaver.save(registry, "%s.%s" % [save_path, _get_save_extension()])


func _parse_registry(dict: Dictionary, base_dir: String) -> MHTargetRegistry:
	var registry := MHTargetRegistry.new()
	for label: String in dict:
		var section := _parse_section(dict[label], base_dir.path_join(label))
		registry.sections.push_back(section)

	return registry


func _parse_section(dict: Dictionary, section_dir: String) -> MHTargetSection:
	var section := MHTargetSection.new()
	section.label = dict.label
	section.include_per_default = dict.include_per_default

	for category_dict: Dictionary in dict.categories:
		var category := _parse_category(category_dict, section_dir)
		section.categories.push_back(category)

	return section


func _parse_category(dict: Dictionary, section_dir: String) -> MHTargetCategory:
	var category := MHTargetCategory.new()
	category.has_left_and_right = dict.has_left_and_right
	category.label = dict.label
	category.name = dict.name

	var opposites: Dictionary = dict.get("opposites", { })
	if opposites:
		category.opposites = _parse_opposites(opposites)

	for target_name: String in dict.targets:
		category.targets[target_name] = _load_target(target_name, section_dir)

	return category


func _parse_opposites(dict: Dictionary) -> MHTargetOpposites:
	var opposites := MHTargetOpposites.new()
	opposites.negative_left = dict["negative-left"]
	opposites.negative_right = dict["negative-right"]
	opposites.negative_unsided = dict["negative-unsided"]
	opposites.positive_left = dict["positive-left"]
	opposites.positive_right = dict["positive-right"]
	opposites.positive_unsided = dict["positive-unsided"]
	return opposites


func _load_target(target_name: String, section_dir: String) -> MHTarget:
	var base_path := section_dir.path_join(target_name)
	var full_path := base_path + ".target"
	if FileAccess.file_exists(full_path):
		return ResourceLoader.load(full_path) as MHTarget

	full_path = base_path + ".target.gz"
	if FileAccess.file_exists(full_path):
		return ResourceLoader.load(full_path) as MHTarget

	push_error("Unable to find '%s'" % base_path)
	return null
