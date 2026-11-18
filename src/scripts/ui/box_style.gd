extends RefCounted

const Palette = preload("res://src/configs/ui/ui_palette.gd")

# 過關獎勵、商店與賣出按鈕共用的平面方框樣式。
static func flat(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(Palette.BORDER_WIDTH)
	style.set_corner_radius_all(Palette.RADIUS)
	return style

# 按鈕各狀態共用外框，只改變底色；停用時文字轉暗。
static func apply_button(button: Button, font_size: int) -> void:
	for state in Palette.BUTTON_COLORS:
		button.add_theme_stylebox_override(state, flat(Palette.BUTTON_COLORS[state], Palette.BUTTON_BORDER))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_font_size_override("font_size", font_size)
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color, Palette.BUTTON_TEXT)
	button.add_theme_color_override("font_disabled_color", Palette.BUTTON_DISABLED_TEXT)
