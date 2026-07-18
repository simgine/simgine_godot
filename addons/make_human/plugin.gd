@tool
extends EditorPlugin

const ASSETS_DIR_SETTING := "make_human/general/assets"

var _obj_importer := MakeHumanObjImporter.new()
var _target_importer := MakeHumanTargetImporter.new()
var _mhmat_importer := MakeHumanMhmatImporter.new()
var _mhclo_importer := MakeHumanMhcloImporter.new()


func _enter_tree() -> void:
	if not ProjectSettings.has_setting(ASSETS_DIR_SETTING):
		ProjectSettings.set_setting(ASSETS_DIR_SETTING, "")

	ProjectSettings.set_initial_value(ASSETS_DIR_SETTING, "")
	ProjectSettings.add_property_info(
		{
			"name": ASSETS_DIR_SETTING,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR,
		},
	)

	add_import_plugin(_obj_importer)
	add_import_plugin(_target_importer)
	add_import_plugin(_mhmat_importer)
	add_import_plugin(_mhclo_importer)


func _exit_tree() -> void:
	remove_import_plugin(_obj_importer)
	remove_import_plugin(_target_importer)
	remove_import_plugin(_mhmat_importer)
	remove_import_plugin(_mhclo_importer)
