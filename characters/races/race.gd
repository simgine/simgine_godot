class_name Race
extends Resource
## A playable race.
##
## Holds only metadata and a path to scene, so actual assets are loaded on
## instantiation.

## Display name.
@export var name: String

## A path to a [Character] scene.
@export_file("*.tscn") var scene_path: String


## Creates a character outside the scene tree.
##
## Returns null if the scene cannot be loaded or has an invalid root.
func create_character() -> Character:
	var scene := ResourceLoader.load(scene_path) as PackedScene
	if not scene:
		Log.error("Unable to load character scene '%s'", scene_path)
		return null

	var node := scene.instantiate()
	var character := node as Character
	if not character:
		if node:
			node.free()
		Log.error("'%s' is not a Character", scene_path)
		return null

	return character


## Returns list of all races from the project resources.
static func get_available_races() -> Array[Race]:
	const RACES_DIR := "res://characters/races"

	var races: Array[Race] = []
	var entries := ResourceLoader.list_directory(RACES_DIR)
	entries.sort()

	for file_name in entries:
		if file_name.get_extension() != "tres":
			continue

		var race := ResourceLoader.load(RACES_DIR.path_join(file_name)) as Race
		if race:
			races.append(race)
		else:
			Log.warn("Resource '%s' is not a Race, unloading", file_name)

	return races
