@tool
extends RefCounted

# bg/01：原圖比例、像素尺寸及圖樣排列。
const REFERENCE_SIZE = Vector2(1152, 648)
const BASE_COLOR = Color("344f71")
const COLUMN_STEP = Vector2(224, 0)
const ROW_STEP = Vector2(-16, 228)
const ORIGIN = Vector2(-10, -42)
const CAT_TEXTURE_OFFSET = Vector2(0, -27)
const TEXTURE_PATHS: PackedStringArray = [
	"res://src/assets/bg/01/gameplay_bg_cat00.png",
	"res://src/assets/bg/01/gameplay_bg_cat01.png",
	"res://src/assets/bg/01/gameplay_bg_cat02.png",
	"res://src/assets/bg/01/gameplay_bg_cat03.png",
]

# 方塊斜邊從頂端到下端的位移；速度單位為參考畫面的 px/s。
const SCROLL_DIRECTION = Vector2(-105, 195)
const SCROLL_SPEED = 8.0

# 分布規則。SEED 固定時，重新開啟場景會得到同一組圖樣。
const MAX_CONSECUTIVE_CATS = 3
const MIN_CATS_PER_SCREEN = 2
const SEED = 72601
const EXTRA_CAT_CHANCE = 0.12
const MIN_PATTERN_SIDE = 12

# 任意連續 3 欄 × 2 列皆滿足最低貓數，包含循環接縫。
# 這個區塊比 gameplay 中央可見區小，移動途中也能保證貓臉入鏡。
const DENSITY_WINDOW = Vector2i(3, 2)
const CAT_FACE_BOUNDS = Rect2(6, 147, 76, 59)

# 核心邏輯測試使用的組合與移動採樣範圍。
const TEST_RUN_LIMITS: PackedInt32Array = [1, 2, 3]
const TEST_MINIMUMS: PackedInt32Array = [1, 2, 3, 4]
const TEST_SEED_COUNT = 8
const TEST_PHASE_STEPS = 24
