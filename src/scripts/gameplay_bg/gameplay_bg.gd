@tool
extends Control

const Config = preload("res://src/configs/gameplay_bg/gameplay_bg_config.gd")
const Pattern = preload("res://src/service/gameplay_bg/background_pattern.gd")
const Layout = preload("res://src/service/gameplay_bg/background_layout.gd")

@export var preview_motion: bool = false
@export_tool_button("重新產生背景", "Reload") var rebuild_preview: Callable = rebuild

var _pattern = Pattern.new()
var _textures: Array[Texture2D] = []
var _phase := Vector2.ZERO


func _ready() -> void:
	resized.connect(queue_redraw)
	rebuild()


func rebuild() -> void:
	_textures.clear()
	for path in Config.TEXTURE_PATHS:
		_textures.append(load(path) as Texture2D)
	_phase = Vector2.ZERO
	if not _pattern.build(
		Config.MAX_CONSECUTIVE_CATS, Config.MIN_CATS_PER_SCREEN,
		Config.SEED, Config.EXTRA_CAT_CHANCE
	):
		push_error("背景分布無法滿足 config：請降低最低貓數或提高連續貓上限。")
	queue_redraw()


func _process(delta: float) -> void:
	if _pattern.tiles.is_empty() or (Engine.is_editor_hint() and not preview_motion):
		return
	_phase = Layout.advance_phase(_phase, delta, _pattern.grid_size)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Config.BASE_COLOR)
	if _pattern.tiles.is_empty() or _textures.is_empty():
		return
	draw_set_transform(Vector2.ZERO, 0.0, size / Config.REFERENCE_SIZE)
	for item in Layout.visible_cells(_phase):
		var tile: int = _pattern.tile_at(item.cell)
		var position_value: Vector2 = item.position
		if tile > 0:
			position_value += Config.CAT_TEXTURE_OFFSET
		draw_texture(_textures[tile], position_value)
