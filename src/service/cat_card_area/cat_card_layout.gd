extends RefCounted

const Config = preload("res://src/configs/cat_card_area/cat_card_area_config.gd")


static func get_positions(card_count: int, card_size: Vector2) -> PackedVector2Array:
	var lower_count := ceili(card_count / 2.0)
	var upper_count := floori(card_count / 2.0)
	var base_columns := ceili(Config.BASE_CARD_COUNT / 2.0)
	var base_width := base_columns * card_size.x + (base_columns - 1) * Config.BASE_CARD_GAP
	var step := card_size.x + Config.BASE_CARD_GAP
	if lower_count > base_columns:
		step = (base_width - card_size.x) / (lower_count - 1)
	var upper_offset := minf(Config.TOP_ROW_OFFSET_X, (lower_count - upper_count) * step)
	var positions := PackedVector2Array()
	for index in range(card_count):
		var column := floori(index / 2.0)
		var point := Vector2(column * step, card_size.y + Config.ROW_GAP)
		if index % 2 == 1:
			point = Vector2(point.x + upper_offset, 0)
		positions.append(point.round())
	return positions
