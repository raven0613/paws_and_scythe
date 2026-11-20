extends RefCounted

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Modifiers = preload("res://src/service/cat_cards/rule_modifiers.gd")
const Market = preload("res://src/service/shop/cat_market.gd")

static func capture(game: RefCounted, phase: String) -> Dictionary:
	var board: Array = []
	for cell in game.board:
		board.append({"cell": cell, "card": game.board[cell]})
	var offers: Array = []
	if phase == "shop":
		for slot in game.shop.offers.size():
			var id: String = game.shop.offers[slot]
			offers.append({"slot": slot, "cat": id,
				"price": Market.price(id) if id != "" else 0,
				"rarity": Catalog.CARDS[id].rarity if id != "" else "",
				"can_buy": game.can_buy(slot)})
	var rules := {}
	for id in game.cats.ids:
		if Catalog.CARDS[id].has("rules"):
			rules[id] = Catalog.CARDS[id].rules
	return json_value({
		"level": game.level, "target": game.target(), "score": game.score,
		"phase": phase, "status": game.Status.keys()[game.status].to_lower(),
		"loss_reason": game.loss_reason, "money": game.money,
		"turns_left": game.turns_left, "discards_left": game.discards_left,
		"swaps_used": game.swaps_used, "digs_used": game.digs_used,
		"board_limit": game.board_limit(), "hand_limit": game.hand_limit,
		"extended_min": Modifiers.extended_min(game.cats.ids), "rule_modifiers": rules,
		"cats": game.cats.ids, "cat_state": game.cat_state(), "board": board,
		"hand": game.hand, "played": game.played, "history": game.history,
		"draw_pile_count": game.deck.draw_pile.size(), "discard_pile": game.deck.discard_pile,
		"deck_rng_state": str(game.deck.rng.state),
		"shop_rng_state": str(game.shop.rng.state), "offers": offers,
		"rerolls": game.shop.rerolls if phase == "shop" else 0,
		"reroll_cost": game.shop.reroll_cost() if phase == "shop" else 0,
		"reward": game.reward,
	})

# Copy into JSON-native values; coordinates remain numeric pairs.
static func json_value(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key in value:
			result[str(key)] = json_value(value[key])
		return result
	if value is Array or value is PackedStringArray:
		var result: Array = []
		for item in value:
			result.append(json_value(item))
		return result
	if value is Vector2i or value is Vector2:
		return [value.x, value.y]
	if value is Color:
		return value.to_html()
	if value is StringName:
		return str(value)
	return value
