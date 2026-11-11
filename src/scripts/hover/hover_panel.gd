extends Panel

const Config = preload("res://src/configs/hover/hover_config.gd")

func _ready() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Config.BACKGROUND
	panel.border_color = Config.BORDER
	panel.set_border_width_all(Config.BORDER_WIDTH)
	panel.set_corner_radius_all(Config.CORNER_RADIUS)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		panel.set_content_margin(side, Config.PADDING)
	add_theme_stylebox_override("panel", panel)
	$title.add_theme_font_size_override("font_size", Config.TITLE_SIZE)
	$title.add_theme_color_override("font_color", Config.TITLE_COLOR)
	$description.add_theme_font_size_override("font_size", Config.BODY_SIZE)
	$description.add_theme_color_override("font_color", Config.TEXT_COLOR)

func present(title: String, description: String, source_rect: Rect2) -> void:
	$title.text = title
	$description.text = description
	var bounds := get_viewport_rect().grow(-Config.SCREEN_MARGIN)
	var natural_width := 0.0
	for label: Label in [$title, $description]:
		var font := label.get_theme_font("font")
		var font_size := label.get_theme_font_size("font_size")
		for line in label.text.split("\n"):
			natural_width = maxf(natural_width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var panel_width := minf(ceilf(natural_width) + Config.PADDING * 2, minf(Config.MAX_WIDTH, bounds.size.x))
	var text_width := panel_width - Config.PADDING * 2
	# 先設定換行寬度，再量測文字高度，進入當幀即完成排版。
	var bottom: float = Config.PADDING
	for label in [$title, $description]:
		label.visible = not label.text.is_empty()
		if not label.visible:
			continue
		label.size.x = text_width
		label.size.y = label.get_minimum_size().y
		label.position = Vector2(Config.PADDING, bottom)
		bottom += label.size.y + Config.SPACING
	size = Vector2(panel_width, bottom - Config.SPACING + Config.PADDING)
	var target := Vector2(source_rect.end.x + Config.GAP, source_rect.position.y)
	if target.x + size.x > bounds.end.x:
		target.x = source_rect.position.x - size.x - Config.GAP
	global_position = target.clamp(bounds.position, (bounds.end - size).max(bounds.position))
	show()
