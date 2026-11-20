extends RefCounted

const Config = preload("res://src/configs/cat_card_area/cat_card_area_config.gd")


# 上下兩排交錯填入，張數為奇數時下排多一張；依上排左到右、再下排左到右排序後，索引小於此值的貓牌位於上排。
static func upper_count(card_count: int) -> int:
	return floori(card_count / 2.0)


static func get_positions(card_count: int, card_size: Vector2) -> PackedVector2Array:
	var upper := upper_count(card_count)
	var lower := card_count - upper
	var base_columns := ceili(Config.BASE_CARD_COUNT / 2.0)
	var base_width := base_columns * card_size.x + (base_columns - 1) * Config.BASE_CARD_GAP
	var step := card_size.x + Config.BASE_CARD_GAP
	if lower > base_columns:
		step = (base_width - card_size.x) / (lower - 1)
	var upper_offset := minf(Config.TOP_ROW_OFFSET_X, (lower - upper) * step)
	var positions := PackedVector2Array()
	for index in range(card_count):
		var column := floori(index / 2.0)
		var point := Vector2(column * step, card_size.y + Config.ROW_GAP)
		if index % 2 == 1:
			point = Vector2(point.x + upper_offset, 0)
		positions.append(point.round())
	return positions
