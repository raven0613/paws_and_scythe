extends SceneTree

const Config = preload("res://src/configs/cat_card_area/cat_card_area_config.gd")
const Feedback = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const Layout = preload("res://src/service/cat_card_area/cat_card_layout.gd")
const Order = preload("res://src/service/cat_card_area/cat_order.gd")
var failures := 0

func _init() -> void:
	_test_nearest()
	_test_moved()
	print("Cat drag order: %d failures" % failures)
	quit(1 if failures else 0)

# 卡片停在任一槽位或稍微偏離時，插入位置為該槽位；拖到遠處時取最近的槽位。
func _test_nearest() -> void:
	for count in range(1, Config.DEFAULT_CARD_COUNT + 1):
		var slots := _slots(count)
		for index in count:
			var offset := Feedback.CARD_SIZE * 0.2
			_check(Order.nearest_slot(slots, slots[index]) == index, "A card resting on slot %d of %d inserts there." % [index, count])
			_check(Order.nearest_slot(slots, slots[index] + offset) == index, "A card near slot %d of %d inserts there." % [index, count])
	var slots := _slots(Config.DEFAULT_CARD_COUNT)
	var far_left := Vector2(-1000.0, slots[Layout.upper_count(slots.size())].y)
	_check(Order.nearest_slot(slots, far_left) == Layout.upper_count(slots.size()), "Far to the lower-left inserts at the first lower slot.")
	var far_above := Vector2(slots[1].x, -1000.0)
	_check(Order.nearest_slot(slots, far_above) == 1, "Far above an upper slot inserts at that slot.")
	var far_right := Vector2(1000.0, slots[-1].y)
	_check(Order.nearest_slot(slots, far_right) == slots.size() - 1, "Far to the lower-right inserts at the last slot.")

# 移動的貓牌插入目標位置，其餘維持相對順序；放回原位時排序不變。
func _test_moved() -> void:
	var ids := ["a", "b", "c", "d", "e"]
	_check(Order.moved(ids, "a", 3) == ["b", "c", "d", "a", "e"], "Moving forward shifts the cards in between back.")
	_check(Order.moved(ids, "d", 0) == ["d", "a", "b", "c", "e"], "Moving backward shifts the cards in between forward.")
	_check(Order.moved(ids, "e", 4) == ids, "Dropping on the original slot keeps the order.")
	_check(ids == ["a", "b", "c", "d", "e"], "The original order stays unchanged.")

# 與貓牌區相同：依上排左到右、再下排左到右排列。
func _slots(count: int) -> Array:
	var slots := Array(Layout.get_positions(count, Feedback.CARD_SIZE))
	slots.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	return slots

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
