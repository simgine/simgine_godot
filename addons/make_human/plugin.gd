@tool
class_name MakeHumanPlugin
extends EditorPlugin

const DATA_DIR_SETTING := "make_human/data_dir"

var _obj_importer := MHObjImporter.new()
var _target_importer := MHTargetImporter.new()
var _json_importer := MHJSONImporter.new()
var _mhmat_importer := MHMatImporter.new()
var _mhclo_importer := MHCloImporter.new()


func _enter_tree() -> void:
	if not ProjectSettings.has_setting(DATA_DIR_SETTING):
		ProjectSettings.set_setting(DATA_DIR_SETTING, "")

	ProjectSettings.set_initial_value(DATA_DIR_SETTING, "")
	ProjectSettings.add_property_info(
		{ "name": DATA_DIR_SETTING, "type": TYPE_STRING, "hint": PROPERTY_HINT_DIR },
	)

	add_import_plugin(_obj_importer)
	add_import_plugin(_target_importer)
	add_import_plugin(_json_importer)
	add_import_plugin(_mhmat_importer)
	add_import_plugin(_mhclo_importer)


func _exit_tree() -> void:
	remove_import_plugin(_obj_importer)
	remove_import_plugin(_target_importer)
	remove_import_plugin(_json_importer)
	remove_import_plugin(_mhmat_importer)
	remove_import_plugin(_mhclo_importer)
