@tool
extends RefCounted

const Config = preload("res://src/configs/fonts/font_config.gd")
static var _shared_font: FontFile
static var _pixel_font: FontFile

static func get_font() -> FontFile:
	if _shared_font == null:
		_shared_font = _create_font(Config.NUMBER_PIXEL_ENABLED, Config.CHINESE_PIXEL_ENABLED)
	return _shared_font

static func get_pixel_font() -> FontFile:
	if _pixel_font == null:
		_pixel_font = _create_font(true, true)
	return _pixel_font

static func _create_font(number_pixel: bool, chinese_pixel: bool) -> FontFile:
	var font := _prepare(Config.NUMBER_FONT, number_pixel)
	font.fallbacks = [_prepare(Config.CHINESE_FONT, chinese_pixel)]
	return font

static func _prepare(source: FontFile, pixel: bool) -> FontFile:
	var font := source.duplicate() as FontFile
	font.allow_system_fallback = false
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE if pixel else TextServer.FONT_ANTIALIASING_GRAY
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED if pixel else TextServer.SUBPIXEL_POSITIONING_AUTO
	font.hinting = TextServer.HINTING_NONE if pixel else TextServer.HINTING_NORMAL
	font.oversampling = Config.PIXEL_OVERSAMPLING if pixel else Config.SMOOTH_OVERSAMPLING
	font.multichannel_signed_distance_field = false
	font.generate_mipmaps = false
	return font
