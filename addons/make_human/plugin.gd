@tool
extends EditorPlugin

var _obj_importer := MakeHumanObjImporter.new()
var _target_importer := MakeHumanTargetImporter.new()
var _mhmat_importer := MakeHumanMhmatImporter.new()
var _mhclo_importer := MakeHumanMhcloImporter.new()


func _enter_tree() -> void:
	add_import_plugin(_obj_importer)
	add_import_plugin(_target_importer)
	add_import_plugin(_mhmat_importer)
	add_import_plugin(_mhclo_importer)


func _exit_tree() -> void:
	remove_import_plugin(_obj_importer)
	remove_import_plugin(_target_importer)
	remove_import_plugin(_mhmat_importer)
	remove_import_plugin(_mhclo_importer)
