@tool
class_name MakeHumanPlugin
extends EditorPlugin

const BASE_OBJ_SETTING := "make_human/paths/base_obj"
const TARGET_JSON_SETTING := "make_human/paths/target_json"

var _obj_importer := MHObjImporter.new()
var _target_importer := MHTargetImporter.new()
var _target_json_importer := MHTargetJSONImporter.new()
var _macro_json_importer := MHMacroJSONImporter.new()
var _mhmat_importer := MHMatImporter.new()
var _mhclo_importer := MHCloImporter.new()


func _enter_tree() -> void:
	_add_setting(BASE_OBJ_SETTING, TYPE_STRING, PROPERTY_HINT_FILE)
	_add_setting(TARGET_JSON_SETTING, TYPE_STRING, PROPERTY_HINT_FILE)

	add_import_plugin(_obj_importer)
	add_import_plugin(_target_importer)
	add_import_plugin(_target_json_importer)
	add_import_plugin(_macro_json_importer)
	add_import_plugin(_mhmat_importer)
	add_import_plugin(_mhclo_importer)


func _exit_tree() -> void:
	remove_import_plugin(_obj_importer)
	remove_import_plugin(_target_importer)
	remove_import_plugin(_target_json_importer)
	remove_import_plugin(_macro_json_importer)
	remove_import_plugin(_mhmat_importer)
	remove_import_plugin(_mhclo_importer)


func _add_setting(path: String, type: Variant.Type, hint: PropertyHint) -> void:
	if not ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, "")

	ProjectSettings.set_initial_value(path, "")
	ProjectSettings.add_property_info({ "name": path, "type": type, "hint": hint })
