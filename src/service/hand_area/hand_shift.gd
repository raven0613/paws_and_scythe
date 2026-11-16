extends RefCounted

# current 與 order 為手牌槽位上的卡牌 ID，order 為更新後的順序。回傳留在手上且槽位改變的牌，
# 依新槽位由左至右排列，越靠近空位的越先出發，delay 每張遞增 interval。
static func plan(current: Array, order: Array, interval: float) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	for from in current.size():
		var to := order.find(current[from])
		if to >= 0 and to != from:
			moves.append({"id": current[from], "from": from, "to": to})
	moves.sort_custom(func(a, b): return a.to < b.to)
	for index in moves.size():
		moves[index].delay = index * interval
	return moves

# 底板右緣跟隨最後一張移動的牌，沒有牌移動時立即開始。
static func edge_delay(moves: Array[Dictionary]) -> float:
	return moves.back().delay if not moves.is_empty() else 0.0
