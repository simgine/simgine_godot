@tool
class_name LogPlugin
extends EditorPlugin

const FILTERS_SETTING := "debug/logging/filters"
const DEFAULT_FILTERS := ""


func _enter_tree() -> void:
	if not ProjectSettings.has_setting(FILTERS_SETTING):
		ProjectSettings.set_setting(FILTERS_SETTING, DEFAULT_FILTERS)

	ProjectSettings.set_initial_value(FILTERS_SETTING, DEFAULT_FILTERS)
	ProjectSettings.add_property_info({ "name": FILTERS_SETTING, "type": TYPE_STRING })
