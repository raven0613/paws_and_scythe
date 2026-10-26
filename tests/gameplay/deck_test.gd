extends SceneTree

const Config = preload("res://src/configs/gameplay/game_rules.gd")
const Deck = preload("res://src/service/gameplay/deck.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")
var failures := 0

func _init() -> void:
	var deck = Deck.new()
	deck.rng.seed = Config.TEST_SEED
	deck.reset()
	var all: Array = deck.draw(Config.DECK_SIZE)
	var sorted := all.duplicate()
	sorted.sort()
	_check(sorted == range(Config.DECK_SIZE), "Full standard deck contains each unique card")
	_check(all != sorted, "Deck is shuffled")
	for suit in Config.SUITS.size():
		for rank_value in range(1, Config.RANKS.size() + 1):
			var card := Cards.id(rank_value, suit)
			_check(Cards.rank(card) == rank_value and Cards.suit(card) == suit, "Rank and suit roundtrip")
	_check(deck.draw(1).is_empty(), "Exhaustion returns actual available count")
	var discarded: Array = all.slice(0, Config.MAX_DISCARD)
	deck.discard_pile.append_array(discarded)
	var recycled: Array = deck.draw(Config.HAND_LIMIT)
	recycled.sort()
	discarded.sort()
	_check(recycled == discarded and deck.discard_pile.is_empty(), "Only discarded cards recycle")
	deck.reset()
	_check(deck.draw_pile.size() == Config.DECK_SIZE and deck.discard_pile.is_empty(), "Reset rebuilds complete deck")
	var second = Deck.new()
	second.rng.seed = Config.TEST_SEED
	second.reset()
	_check(second.draw(Config.DECK_SIZE) == all, "Seeded shuffle is reproducible")
	print("Deck tests: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
