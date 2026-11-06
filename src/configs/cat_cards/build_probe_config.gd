extends RefCounted

# 完成盤面探針：明確比較構築產出，抽牌與形成速度由實際試玩量測。
const CASES = {
	"six_card_flush": {
		"cats": ["suited", "long", "solo", "copy", "single_length"],
		"lines": [{"ranks": [2, 4, 6, 8, 10, 12], "suits": [0, 0, 0, 0, 0, 0], "origin": Vector2i.ZERO}],
	},
	"eight_card_flush": {
		"cats": ["suited", "long", "solo", "copy", "single_length"],
		"lines": [{"ranks": [2, 4, 6, 8, 10, 11, 12, 13], "suits": [0, 0, 0, 0, 0, 0, 0, 0], "origin": Vector2i.ZERO}],
	},
	"two_straights": {
		"cats": ["straights", "alternating", "compact", "sixfold", "combo"],
		"lines": [
			{"ranks": [2, 3, 4, 5, 6, 7], "suits": [0, 1, 0, 1, 0, 1], "origin": Vector2i.ZERO},
			{"ranks": [8, 9, 10, 11, 12, 13], "suits": [0, 1, 0, 1, 0, 1], "origin": Vector2i(0, 1)},
		],
	},
	"hollow_houses": {
		"cats": ["houses", "alternating", "compact", "combo", "hollow"],
		"lines": [
			{"ranks": [8, 8, 8, 10, 10], "suits": [0, 1, 3, 1, 0], "origin": Vector2i.ZERO},
			{"ranks": [9, 9, 9, 11, 11], "suits": [0, 1, 3, 1, 0], "origin": Vector2i(0, 2)},
			{"ranks": [2, 3], "suits": [0, 0], "origin": Vector2i(0, 1)},
			{"ranks": [4, 5], "suits": [0, 0], "origin": Vector2i(3, 1)},
		],
	},
	"consecutive_houses": {
		"cats": ["consecutive", "houses", "alternating", "compact", "hollow"],
		"lines": [
			{"ranks": [8, 8, 8, 10, 10], "suits": [0, 1, 3, 1, 0], "origin": Vector2i.ZERO},
			{"ranks": [9, 9, 9, 11, 11], "suits": [0, 1, 3, 1, 0], "origin": Vector2i(0, 2)},
			{"ranks": [2, 3], "suits": [0, 0], "origin": Vector2i(0, 1)},
			{"ranks": [4, 5], "suits": [0, 0], "origin": Vector2i(3, 1)},
		],
	},
	"three_quad_islands": {
		"cats": ["consecutive", "matching", "quads", "compact", "islands"],
		"lines": [
			{"ranks": [8, 8, 8, 8], "suits": [0, 1, 2, 3], "origin": Vector2i.ZERO},
			{"ranks": [9, 9, 9, 9], "suits": [0, 1, 2, 3], "origin": Vector2i(0, 2)},
			{"ranks": [10, 10, 10, 10], "suits": [0, 1, 2, 3], "origin": Vector2i(0, 4)},
		],
	},
}
