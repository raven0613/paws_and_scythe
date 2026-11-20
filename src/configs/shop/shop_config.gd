extends RefCounted

# 商店三區的格數；轉換牌／任務單／貓點心區與卡包區目前呈現空格。
const CAT_SLOTS = 2
const ITEM_SLOTS = 2
const PACK_SLOTS = 2
# 重骰只刷新貓牌區；每次進入商店從 REROLL_BASE 起算，每重骰一次增加 REROLL_STEP。
const REROLL_BASE = 3
const REROLL_STEP = 1
# 每格獨立依權重抽稀有度；抽中的稀有度沒有可上架的貓牌時，依 RARITY_ORDER 先往低稀有度、再往高稀有度遞補。
const RARITY_ORDER = ["R", "SR", "SSR"]
const RARITY_WEIGHTS = {"R": 70, "SR": 25, "SSR": 5}
# 賣價依稀有度；買價依每張貓牌各自設定。
const SELL_PRICES = {"R": 2, "SR": 4, "SSR": 6}
const CAT_PRICES = {
	"peace": 5,
	"matching": 6,
	"crossing": 6,
	"combo": 6,
	"solo": 8,
	"copy": 8,
	"pairs": 6,
	"variety": 5,
	"alternating": 6,
	"growth": 6,
	"small": 9,
	"unique": 9,
	"suited": 5,
	"long": 5,
	"reserve": 5,
	"discarding": 5,
	"frugal": 5,
	"industry": 6,
	"champion": 8,
	"strays": 8,
	"hollow": 9,
	"islands": 8,
	"compact": 9,
	"single_length": 13,
	"sixfold": 8,
	"straights": 5,
	"flushes": 5,
	"houses": 5,
	"quads": 5,
	"consecutive": 5,
	"bunk": 13,
}
