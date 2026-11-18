extends RefCounted

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
var ids: Array = []
var settlements := 0
var operations := 0

func select(selected: Array) -> bool:
	if not Catalog.valid_selection(selected):
		return false
	operations = 0
	ids = selected.duplicate()
	settlements = 0
	return true

func is_full() -> bool:
	return ids.size() >= Catalog.MAX_EQUIPPED

# 新取得的貓牌排在最後，沿用整局已確認的操作累積。
func add(id: String) -> bool:
	if not Catalog.valid_selection(ids + [id]):
		return false
	ids.append(id)
	return true

func remove(id: String) -> bool:
	if not ids.has(id):
		return false
	ids.erase(id)
	return true

func reorder(ordered: Array) -> bool:
	if ordered.size() != ids.size() or not Catalog.valid_selection(ordered):
		return false
	if not ordered.all(func(id): return ids.has(id)):
		return false
	ids = ordered.duplicate()
	return true

func begin_level() -> void:
	settlements = 0

func commit(confirmed_operations: int = 0) -> void:
	settlements += 1
	operations += confirmed_operations
