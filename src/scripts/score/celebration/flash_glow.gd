@tool
extends Node2D

const Config = preload("res://src/configs/score/celebration_config.gd")
var width := 0.0
var height := 0.0
var amount := 0.0

# 數字後方由內而外逐層擴散的白色橢圓，疊加成中心最亮的過曝光暈。
func _draw() -> void:
	if amount <= 0.0:
		return
	var core := Vector2(width, height) * Config.FLASH_GLOW_SIZE
	var color := Config.FLASH_GLOW_COLOR
	color.a = amount * Config.FLASH_GLOW_ALPHA / Config.FLASH_GLOW_LAYERS
	for layer in range(Config.FLASH_GLOW_LAYERS, 0, -1):
		var radius := core + Config.FLASH_GLOW_SPREAD * float(layer) / Config.FLASH_GLOW_LAYERS
		draw_set_transform(Vector2.ZERO, 0.0, radius)
		draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO)
