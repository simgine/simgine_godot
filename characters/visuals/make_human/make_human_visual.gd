@tool
class_name MakeHumanVisual
extends CharacterVisual

@onready var body_instance: MHBodyInstance = %Body

var _attachments: Dictionary[LookItem, Object]


func _attach_item(item: LookItem) -> bool:
	if _attachments.has(item):
		return false

	var attachment := _create_attachment(item.asset_path)
	if not attachment:
		return false

	var material := attachment as StandardMaterial3D
	if material:
		body_instance.material_override = material
	else:
		body_instance.add_child(attachment)

	_attachments[item] = attachment
	return true


static func _create_attachment(asset_path: String) -> Object:
	var res := ResourceLoader.load(asset_path)
	if not res:
		Log.error("Unable to load '%s'", asset_path)
		return null

	var material := res as StandardMaterial3D
	if material:
		return material

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
			Log.error("PackedScene '%s' root is not an MHProxyInstance", asset_path)
			node.free()
			return null

		return instance

	Log.error(
		"'%s' must be a StandardMaterial3D, MHProxy resource, or PackedScene with an MHProxyInstance root",
		asset_path,
	)
	return null


func _detach_item(item: LookItem) -> void:
	var attachment: Object = _attachments.get(item)
	if not attachment:
		return

	var material := attachment as StandardMaterial3D
	if material:
		# A conflicting material may already have replaced this one.
		if body_instance.material_override == material:
			body_instance.material_override = null
	else:
		var instance := attachment as MHProxyInstance
		instance.queue_free()

	_attachments.erase(item)


func _get_items_dir() -> String:
	return "res://characters/visuals/make_human/items/"
