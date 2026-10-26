extends SceneTree

const Config = preload("res://src/configs/cat_card_area/cat_card_area_config.gd")
const Layout = preload("res://src/service/cat_card_area/cat_card_layout.gd")
const CardTexture = preload("res://src/assets/cat_card/cat_card_match.png")


func _init() -> void:
	var card_size: Vector2 = CardTexture.get_size()
	var base_columns := ceili(Config.BASE_CARD_COUNT / 2.0)
	var base_width := base_columns * card_size.x + (base_columns - 1) * Config.BASE_CARD_GAP
	for count in range(Config.MIN_CARD_COUNT, Config.MAX_CARD_COUNT + 1):
		var positions: PackedVector2Array = Layout.get_positions(count, card_size)
		assert(positions.size() == count, "Each card must receive a position.")
		var upper_right := 0.0
		var lower_right := 0.0
		var previous_x := [-1.0, -1.0]
		for index in range(count):
			var row := index % 2
			var point := positions[index]
			assert(point.x > previous_x[row], "Each row must advance to the right.")
			assert(point.x == roundf(point.x), "Pixel-art positions must use whole pixels.")
			assert(point.x + card_size.x <= base_width, "Cards must stay within the six-card footprint.")
			previous_x[row] = point.x
			if row == 0:
				assert(point.y == card_size.y + Config.ROW_GAP, "Odd-numbered cards fill the lower row.")
				lower_right = point.x + card_size.x
			else:
				assert(point.y == 0.0, "Even-numbered cards fill the upper row.")
				upper_right = point.x + card_size.x
		assert(upper_right <= lower_right, "The upper row must end within the lower row.")
		if count <= Config.BASE_CARD_COUNT:
			for index in range(2, count):
				assert(
					positions[index].x - positions[index - 2].x == card_size.x + Config.BASE_CARD_GAP,
					"Up to six cards must retain the initial gap."
				)
		elif count > Config.BASE_CARD_COUNT:
			assert(positions[2].x - positions[0].x < card_size.x, "Additional cards must overlap.")
	print("Cat card layout passed: alternating rows, initial gap, fixed width and upper-right bound.")
	quit()
