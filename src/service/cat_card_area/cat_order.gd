extends RefCounted

# 拖曳排序的插入位置：slots 依排序位置排列各槽位的卡片左上角，回傳與 point 距離最近的槽位索引。
static func nearest_slot(slots: Array, point: Vector2) -> int:
	var nearest := 0
	for index in slots.size():
		if point.distance_squared_to(slots[index]) < point.distance_squared_to(slots[nearest]):
			nearest = index
	return nearest

# 把 id 移到排序位置 index，其餘貓牌維持原本的相對順序。
static func moved(ids: Array, id: String, index: int) -> Array:
	var result := ids.duplicate()
	result.erase(id)
	result.insert(index, id)
	return result
