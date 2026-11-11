extends SceneTree

const Transition = preload("res://src/service/combo/group_transition.gd")
const Entry = preload("res://src/configs/combo/combo_entry.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
var failures := 0

func _init() -> void:
	var straight := _line("straight", 0, Rules.EXTENDED_MIN)
	var longer := _line("straight", 0, Rules.EXTENDED_MIN + 1)
	_check(Transition.compare([], [straight]).added == [0], "First group enters.")
	_check(Transition.compare([straight], []).removed == [0], "Lost group exits.")
	_check(Transition.compare([straight], [longer]).previous == [0], "Extension retains identity.")
	_check(Transition.compare([longer], [straight]).added.is_empty(), "Shortening retains identity.")
	var pair := _line("pair", 0, 2)
	var three := _line("three", 0, 3)
	var upgrade: Dictionary = Transition.compare([pair], [three])
	_check(upgrade.removed == [0] and upgrade.added == [0], "A different kind replaces the group.")
	var changed := _line("straight", 0, Rules.EXTENDED_MIN)
	changed.score = Rules.HAND_BONUSES.straight * 2
	_check(Transition.compare([straight], [changed]).added.is_empty(), "Score changes and internal card swaps retain identity.")
	var far := _line("straight", Rules.EXTENDED_MIN + 1, Rules.EXTENDED_MIN)
	var joined := _line("straight", 0, Rules.EXTENDED_MIN * 2 + 1)
	var merge: Dictionary = Transition.compare([straight, far], [joined])
	_check(merge.previous == [0] and merge.removed == [1], "Merge retains the first equal-overlap group.")
	var split: Dictionary = Transition.compare([joined], [straight, far])
	_check(split.previous == [0, -1] and split.added == [1], "Split retains one group and introduces the other.")
	_check(Transition.compare([straight], [far]).added == [0], "Disjoint groups have distinct identities.")
	var vertical := _line("straight", 0, Rules.EXTENDED_MIN, Vector2i.DOWN)
	var crossed: Dictionary = Transition.compare([straight, vertical], [vertical, straight])
	_check(crossed.previous == [1, 0], "Intersecting directions retain separate identities across list shifts.")
	var middle := _line("pair", Rules.EXTENDED_MIN * 3, 2)
	var removed: Dictionary = Transition.compare([straight, middle, far], [straight, far])
	_check(removed.previous == [0, 2] and removed.removed == [1], "Removing a middle row preserves later identities.")
	var exact: Dictionary = Transition.compare([straight, far], [joined, far])
	_check(exact.previous == [0, 1], "Exact paths are preserved before overlapping matches.")
	var bent := _line("straight", 0, Rules.EXTENDED_MIN)
	bent.cells[-1] = bent.cells[-2] + Vector2i.DOWN
	var path: Array = bent.cells.duplicate()
	_check(Transition.compare([straight], [bent]).previous == [0], "Path continuity supports a future bend.")
	_check(bent.cells == path, "Matching preserves traversal order.")
	_check(Transition.compare([straight, pair, far], []).removed == [0, 1, 2], "Retirement preserves top-to-bottom order.")
	if failures == 0:
		print("Group transition passed: continuity, replacement, merge, split, direction and traversal order.")
	quit(int(failures > 0))

func _line(kind: String, start: int, count: int, direction := Vector2i.RIGHT) -> Resource:
	var entry := Entry.new()
	entry.kind = kind
	entry.hand_name = Rules.HAND_NAMES[kind]
	entry.direction = direction
	for index in count:
		entry.cells.append(Vector2i(start, 0) + direction * index)
	return entry

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
