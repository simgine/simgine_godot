@tool
class_name MakeHumanVisual
extends CharacterVisual

@onready var body: MHBodyInstance = %Body

var _instances: Dictionary[LookItem, MHProxyInstance]


func _attach_item(item: LookItem) -> bool:
	if _instances.has(item):
		return false

	var instance := _instance_item(item.asset_path)
	if not instance:
		return false

	body.add_child(instance)
	_instances[item] = instance
	return true


static func _instance_item(asset_path: String) -> MHProxyInstance:
	var res := ResourceLoader.load(asset_path)
	if not res:
		Log.error("Unable to load '%s'", asset_path)
		return null

	var proxy := res as MHProxy
	if proxy:
		# Allow paths to a proxy for simple items.
		var instance := MHProxyInstance.new()
		instance.proxy = proxy
		return instance

	var scene := res as PackedScene
	if scene:
		var node := scene.instantiate()
		if not node:
			Log.error("Unable to instantiate '%s'", asset_path)
			return null

		var instance := node as MHProxyInstance
		if not instance:
			Log.error("'%s' does not have an MHProxyInstance root", asset_path)
			node.free()
			return null

		return instance

	Log.error(
		"'%s' must be an MHProxy resource or a PackedScene with an MHProxyInstance root",
		asset_path,
	)
	return null


func _detach_item(item: LookItem) -> void:
	var instance: MHProxyInstance = _instances.get(item)
	if instance:
		instance.queue_free()
		_instances.erase(item)


func set_skin_material(material: Material) -> void:
	body.material_override = material


func _get_items_dir() -> String:
	return "res://characters/visuals/make_human/items/"
