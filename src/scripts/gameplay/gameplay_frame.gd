@tool
extends Control

const Config = preload("res://src/configs/gameplay/gameplay_frame_config.gd")


func _ready() -> void:
	resized.connect(_update_edges)
	_update_edges()


func _has_point(point: Vector2) -> bool:
	var reference := point * Config.REFERENCE_SIZE / size
	if reference.x < Config.LEFT_WIDTH or reference.y < Config.TOP_HEIGHT or reference.y >= Config.REFERENCE_SIZE.y - Config.BOTTOM_HEIGHT:
		return true
	var boss: Sprite2D = $edges/boss_bg
	return boss.is_pixel_opaque(boss.to_local(get_global_transform() * point))


func _update_edges() -> void:
	var width := Config.REFERENCE_SIZE.x
	var height := Config.REFERENCE_SIZE.y
	var bottom := height - Config.BOTTOM_HEIGHT
	$edges.scale = size / Config.REFERENCE_SIZE
	_set_edge($edges/top, [Vector2.ZERO, Vector2(width, 0),
		Vector2(width, Config.TOP_HEIGHT), Vector2(0, Config.TOP_HEIGHT)])
	_set_edge($edges/left, [Vector2(0, Config.TOP_HEIGHT), Vector2(Config.LEFT_WIDTH, Config.TOP_HEIGHT),
		Vector2(Config.LEFT_WIDTH, bottom), Vector2(0, bottom)])
	_set_edge($edges/bottom, [Vector2(0, bottom), Vector2(width, bottom),
		Vector2(width, height), Vector2(0, height)])


func _set_edge(edge: Polygon2D, points: PackedVector2Array) -> void:
	edge.polygon = points
	edge.color = Config.BORDER_COLOR
