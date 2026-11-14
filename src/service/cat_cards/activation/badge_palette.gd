extends RefCounted

const Config = preload("res://src/configs/cat_cards/cat_activation_config.gd")

# 標籤各方塊的填色色標，依主體、第一節、第二節排列；單一色標為純色，多個色標為斜向漸層。
# 總分倍率使用逐節變淺的彩虹，其他效果使用原本的主體與尾巴顏色。
static func fills(event: Dictionary) -> Array[PackedColorArray]:
	var result: Array[PackedColorArray] = []
	if event.target == Config.BADGE_RAINBOW_TARGET:
		for lighten in Config.BADGE_RAINBOW_LIGHTEN:
			result.append(_rainbow(lighten))
		return result
	result.append(PackedColorArray([Config.BADGE_COLOR]))
	for color in Config.TAIL_COLORS:
		result.append(PackedColorArray([color]))
	return result

static func _rainbow(lighten: float) -> PackedColorArray:
	var stops := PackedColorArray()
	for color in Config.BADGE_RAINBOW_COLORS:
		stops.append(color.lerp(Color.WHITE, lighten))
	return stops
