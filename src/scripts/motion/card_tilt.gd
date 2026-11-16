extends RefCounted

const SHADER = preload("res://src/scripts/motion/card_tilt.gdshader")
var _visual: CanvasItem
var _material := ShaderMaterial.new()

# visual 底下的所有圖層共用同一個透視平面，size 為卡片原尺寸，以其中心為傾斜軸。
func _init(visual: CanvasItem, size: Vector2) -> void:
	_visual = visual
	_material.shader = SHADER
	_material.set_shader_parameter("pivot", size / 2)
	_share(visual)

# tilt.x 讓左側靠近鏡頭、tilt.y 讓上緣靠近鏡頭，perspective 為鏡頭到卡面的距離；在 visual 姿態更新後呼叫。
# 傾斜為零時移除材質，卡片以一般方式繪製。
func apply(tilt: Vector2, perspective: float) -> void:
	if tilt.is_zero_approx():
		_visual.material = null
		return
	var transform := _visual.get_global_transform()
	_material.set_shader_parameter("tilt", tilt)
	_material.set_shader_parameter("perspective", perspective)
	_material.set_shader_parameter("card_origin", transform.origin)
	_material.set_shader_parameter("card_x", transform.x)
	_material.set_shader_parameter("card_y", transform.y)
	_visual.material = _material

func _share(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasItem:
			child.use_parent_material = true
		_share(child)
