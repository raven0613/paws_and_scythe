extends SceneTree

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
const Scoring = preload("res://src/service/gameplay/scoring.gd")
const Layout = preload("res://src/service/cat_card_area/cat_card_layout.gd")
const Modifiers = preload("res://src/service/cat_cards/rule_modifiers.gd")
const Effects = preload("res://src/service/cat_cards/effect_rules.gd")
const Resolver = preload("res://src/service/cat_cards/cat_resolver.gd")
var failures := 0
var rows: Dictionary = Catalog.CARDS.bunk.rules.row_potency

func _init() -> void:
	_test_rows()
	_test_boost()
	_test_settlement()
	_test_exempt()
	print("Cat potency: %d failures" % failures)
	quit(1 if failures else 0)

# 排別依貓牌區排版：上排為排序後的前 upper_count 張。
func _test_rows() -> void:
	var ids := ["matching", "suited", "bunk", "combo", "copy"]
	var upper := Layout.upper_count(ids.size())
	var potency := Modifiers.potency(ids)
	for index in ids.size():
		var id: String = ids[index]
		var expected: float = rows.upper if index < upper else rows.lower
		if id == "bunk" or not (Catalog.CARDS[id].stage in Catalog.NUMERIC_STAGES):
			expected = 1.0
		_check(potency[id] == expected, "Row potency follows the arranged row: %s" % id)
	_check(Modifiers.potency(["matching", "combo"]).values().all(func(value): return value == 1.0), "Without the bunk every cat keeps its potency")
	_check(Modifiers.potency(["matching", "bunk"]).matching == rows.upper, "The first of two cats sits in the upper row")
	_check(Modifiers.potency(["bunk", "matching"]).matching == rows.lower, "Reordering moves the other cat to the lower row")

func _test_boost() -> void:
	for potency in [rows.upper, rows.lower]:
		for op in ["add", "scale"]:
			_check(is_equal_approx(Effects.boost(op, Catalog.CARDS.matching.value, potency), Catalog.CARDS.matching.value * potency), "Bonuses scale directly")
		for id in Catalog.CARDS:
			var card: Dictionary = Catalog.CARDS[id]
			if card.get("op") == "multiply" and card.measure == "one":
				var boosted := Effects.boost("multiply", card.value, potency)
				_check(is_equal_approx(boosted - 1.0, (card.value - 1.0) * potency), "Multipliers scale only their extra part: %s" % id)
				_check(boosted > 1.0, "Halved multipliers stay above x1: %s" % id)
		_check(Effects.boost("repeat", Catalog.CARDS.copy.value, potency) == Catalog.CARDS.copy.value, "Extra scoring counts stay unchanged")
	var growth: Dictionary = Catalog.CARDS.growth
	_check(is_equal_approx(Effects.amount(growth, {"settlements": 0}, -1, rows.upper), growth.value * rows.upper), "Current growth bonus reflects the potency")

func _test_settlement() -> void:
	var pair := _line([8, 8])
	var raw := Scoring.evaluate(pair, [])
	var lineup := ["matching", "combo", "bunk"]
	var result := Resolver.resolve(raw, pair, lineup, {})
	var group: float = raw.base + Catalog.CARDS.matching.value * rows.upper
	var multiplier: float = raw.multiplier + Catalog.CARDS.combo.value * rows.lower
	_check(is_equal_approx(result.total, group * multiplier), "Upper bonuses double and lower bonuses halve")
	var matching: Array = result.events.filter(func(e): return e.source == "matching")
	_check(matching.size() == 1 and matching[0].potency == rows.upper, "Effect events record their potency")
	result = Resolver.resolve(raw, pair, ["pairs", "bunk"], {})
	_check(is_equal_approx(result.total, raw.total * (1 + Catalog.CARDS.pairs.value * rows.upper)), "Scale bonuses double their added rate")
	var dragon := _line([3, 4, 5, 6, 7])
	raw = Scoring.evaluate(dragon, [])
	var length: float = raw.groups[0].cells.size()
	for case in [[["single_length", "bunk"], rows.upper], [["bunk", "single_length"], rows.lower]]:
		result = Resolver.resolve(raw, dragon, case[0], {})
		_check(is_equal_approx(result.total, raw.total * (1 + (length - 1) * case[1])), "Length multiplier scales its extra part")

func _test_exempt() -> void:
	var pair := _line([8, 8])
	var raw := Scoring.evaluate(pair, [])
	var copy := Resolver.resolve(raw, pair, ["copy"], {})
	_check(Resolver.resolve(raw, pair, ["copy", "bunk"], {}).total == copy.total, "Extra scoring repeats the same number of times")
	var dragon := _line([3, 4, 5, 6, 7])
	raw = Scoring.evaluate(dragon, [])
	_check(Resolver.resolve(raw, dragon, ["small", "bunk"], {}).total == raw.total, "Conditions keep their thresholds")
	_check(Resolver.resolve(raw, dragon, ["bunk"], {}).total == raw.total, "The bunk alone adds no score")

func _line(ranks: Array) -> Dictionary:
	var board := {}
	for i in ranks.size():
		board[Vector2i(i, 0)] = Cards.id(ranks[i], i % Rules.SUITS.size())
	return board

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
