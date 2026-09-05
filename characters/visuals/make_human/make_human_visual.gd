@tool
class_name MakeHumanVisual
extends CharacterVisual

@onready var body: MHBodyInstance = %Body

var _instances: Dictionary[LookItem, MHProxyInstance]


func _attach(item: LookItem) -> bool:
	if _instances.has(item):
		return false

	var res := ResourceLoader.load(item.asset_path)
	if not res:
		Log.error("Unable to load '%s'", item.asset_path)
		return false

	var instance := _create_instance(res)
	if not instance:
		Log.error("'%s' is not a MakeHuman equipment", item.asset_path)
		return false

	body.add_child(instance)
	_instances[item] = instance
	return true


func _create_instance(res: Resource) -> MHProxyInstance:
	var proxy := res as MHProxy
	if proxy:
		var instance := MHProxyInstance.new()
		instance.proxy = proxy
		return instance

	var scene := res as PackedScene
	if scene:
		var node := scene.instantiate()
		var instance := node as MHProxyInstance
		if not instance:
			node.free()
			return null

		return instance

	return null


func _detach(item: LookItem) -> void:
	var instance: MHProxyInstance = _instances.get(item)
	if instance:
		instance.queue_free()
		_instances.erase(item)
