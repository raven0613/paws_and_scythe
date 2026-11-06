extends RefCounted

const SUITS: Array[StringName] = [&"a", &"b", &"c", &"d"]
const SUIT_NAMES = ["黑桃", "紅心", "方塊", "梅花"]
const RED_SUITS = [1, 2]
const SUIT_COLORS = [Color("203047"), Color("b7384c"), Color("b7384c"), Color("203047")]
const RANKS = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const RANK_POINTS = [14, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
const DECK_SIZE = 52
const STARTING_MONEY = 5
const HAND_LIMIT = 6
const MAX_HAND_LIMIT = 10
const MAX_PLAYS = 6
const SETTLEMENTS = 6
const DISCARDS = 4
const MAX_DISCARD = 3
const SWAP_COSTS = [20, 40]
const DIGS = 2
const DIG_COST = 20
const BOARD_LIMIT = 20
const COMBO_STEP = 0.5
const LENGTH_BONUS = 0.5
const EXTENDED_MIN = 5
const HAND_BONUSES = {
	"pair": 15, "two_pair": 35, "three": 50,
	"straight": 80, "flush": 80, "full_house": 120, "four": 150, "straight_flush": 250,
}
const HAND_NAMES = {
	"high": "高牌", "pair": "對子", "two_pair": "兩對", "three": "三條",
	"straight": "順子", "flush": "同花", "full_house": "葫蘆", "four": "四條", "straight_flush": "同花順",
}
const HAND_ORDER = ["straight_flush", "four", "full_house", "flush", "straight", "three", "two_pair", "pair"]
# 以每三關增加一張貓牌、Lv 16 起五張的構築進度設計。
const LEVEL_TARGETS = [
	300, 650, 1000, 1600, 2200, 3000, 4000,
	5000, 6500, 8000, 9500, 11000, 12500, 14000,
	16000, 18000, 20000, 22000, 24000, 27000, 30000,
]
const TEST_SEED = 72603
const TEST_SAMPLES = 64
