extends RefCounted

# 一對一延續牌型；先保留完整路徑，再依共同格數與原清單順序配對。
# cells 是判定器提供的走訪路徑，保持原順序可直接支援轉彎演出。
static func compare(before: Array, after: Array) -> Dictionary:
	var previous: Array[int] = []
	previous.resize(after.size())
	previous.fill(-1)
	var used := {}
	for next in after.size():
		for old in before.size():
			if not used.has(old) and _same_kind(before[old], after[next]) and before[old].cells == after[next].cells:
				previous[next] = old
				used[old] = true
				break
	var candidates: Array[Dictionary] = []
	for next in after.size():
		if previous[next] >= 0:
			continue
		for old in before.size():
			if used.has(old) or not _same_kind(before[old], after[next]):
				continue
			var overlap := 0
			for cell in after[next].cells:
				if before[old].cells.has(cell):
					overlap += 1
			if overlap > 0:
				candidates.append({"old": old, "next": next, "overlap": overlap})
	candidates.sort_custom(func(a, b):
		if a.overlap != b.overlap:
			return a.overlap > b.overlap
		if a.old != b.old:
			return a.old < b.old
		return a.next < b.next)
	for candidate in candidates:
		if previous[candidate.next] < 0 and not used.has(candidate.old):
			previous[candidate.next] = candidate.old
			used[candidate.old] = true
	var removed: Array[int] = []
	var added: Array[int] = []
	for old in before.size():
		if not used.has(old):
			removed.append(old)
	for next in after.size():
		if previous[next] < 0:
			added.append(next)
	return {"previous": previous, "removed": removed, "added": added}

static func _same_kind(a: Resource, b: Resource) -> bool:
	return a.kind == b.kind and a.hand_name == b.hand_name and a.direction == b.direction
