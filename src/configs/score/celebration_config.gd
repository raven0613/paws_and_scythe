extends RefCounted

# 結算表演等級：NORMAL 為一般表演，HOLOGRAPHIC 為全像彩虹，GALAXY 跑分時為全像彩虹、在最後撞頂時轉場成銀河。
# 最終分數達到關卡目標的 HIGH_SCORE_RATIO 倍使用全像彩虹，達到 GALAXY_SCORE_RATIO 倍使用銀河。
# FORCE_HIGH_SCORE 為每次結算至少使用的等級，NORMAL 時完全依分數判定。
enum Tier { NORMAL, HOLOGRAPHIC, GALAXY }
const FORCE_HIGH_SCORE = Tier.NORMAL
const HIGH_SCORE_RATIO = 1.5
const GALAXY_SCORE_RATIO = 3.0

# 高分特效開關：火焰、撞擊閃白的暖色回落與光暈、畫面震動、火焰噴發、撞擊碎片。
const FIRE_ENABLED = true
const FLASH_TINT_ENABLED = true
const FLASH_GLOW_ENABLED = false
const SCREEN_QUAKE_ENABLED = true
const FIRE_FLARE_ENABLED = true
const DEBRIS_ENABLED = true

# 每段到位與一般結算完成的強度；各段先落定精確數字再演出。
const STEP_DURATION = 0.24
const HIGH_STEP_DURATION = 0.32
const FINAL_DURATION = 0.44
const STEP_SCALE = 1.22
const HIGH_STEP_SCALE = 1.48
const FINAL_SCALE = 1.6
const STEP_TILT = 0.08
const HIGH_STEP_TILT = 0.18
const FINAL_TILT = 0.22
const STEP_SHAKE = Vector2(3, 2)
const HIGH_STEP_SHAKE = Vector2(8, 5)
const FINAL_SHAKE = Vector2(10, 7)
const IMPACT_PEAK = 0.2
const IMPACT_CYCLES = 3.0
const IMPACT_DECAY = 2.0
const COUNT_SHAKE = Vector2(3, 2)
const COUNT_SHAKE_FREQUENCY = Vector2(31, 43)

# 高分結算：放大衝上撞頂並頓停震動，帶初速反彈下墜，一個角先著地，左右搖晃彈跳後兩腳落地。
# 速度以該段平均速度為 1：LAUNCH_SPEED 為離地速度，撞頂時剩 2 - LAUNCH_SPEED；
# REBOUND_SPEED 為離開天花板的向下速度，落地時為 2 - REBOUND_SPEED。
# CEILING_HEIGHT 為上緣上升到天花板的距離；撞頂時尺寸為 LAUNCH_SCALE 乘上 CEILING_SQUASH。
const CEILING_HEIGHT = 25.0
const LAUNCH_DURATION = 0.03
const LAUNCH_SPEED = 1.5
const LAUNCH_SCALE = Vector2(1.25, 1.25)
const CEILING_HOLD = 0.09
const CEILING_SQUASH = Vector2(1.12, 0.9)
const CEILING_TILT = -0.12
const FALL_DURATION = 0.05
const REBOUND_SPEED = 0.7
const FALL_STRETCH = Vector2(0.98, 1.04)
const FLOOR_HOLD = 0.04
const FLOOR_SQUASH = Vector2(1.05, 0.95)
const FLOOR_TILT = 0.1

# 落地搖晃：每次彈起換另一個角著地，最後一次兩腳同時著地；高度、時間與傾斜依 BOUNCE_DECAY 逐次遞減。
# 之後每次著地的數字震動為 FLOOR_SHAKE 乘上 LANDING_SHAKE，並同樣逐次遞減。
const BOUNCE_COUNT = 2
const BOUNCE_DURATION = 0.15
const BOUNCE_HEIGHT = 10.0
const BOUNCE_DECAY = 0.55
const LANDING_SHAKE = 0.35
const LANDING_SHAKE_DURATION = 0.06

# 撞擊力道：天花板為主要撞擊，地板第一個角著地為次要撞擊，兩者各自設定；銀河等級的撞頂閃白由轉場反轉幀取代。
# 震動頻率以每秒次數計，各種撞擊衰減共用 COLLISION_FALLOFF。
const CEILING_SHAKE = Vector2(7, 11)
const CEILING_QUAKE = Vector2(8, 12)
const CEILING_FLASH = 1.0
const CEILING_FLARE = 1.0
const FLOOR_SHAKE = Vector2(3, 5)
const FLOOR_QUAKE = Vector2(3, 5)
const FLOOR_FLASH = 1.0
const FLOOR_FLARE = 0.35
const COLLISION_FALLOFF = 2.0
const COLLISION_SHAKE_FREQUENCY = Vector2(17, 23)

# 撞擊閃白：填色瞬間變白，回落時經過 FLASH_TINT；光暈為數字後方逐層擴散的白色橢圓。
const FLASH_DURATION = 0.2
const FLASH_TINT = Color("ffe9a6")
const FLASH_GLOW_COLOR = Color.WHITE
const FLASH_GLOW_ALPHA = 0.55
const FLASH_GLOW_LAYERS = 6
const FLASH_GLOW_SIZE = 0.6
const FLASH_GLOW_SPREAD = Vector2(46, 30)

# 畫面震動：整個畫面位移，同步以畫面中心微幅放大遮住邊緣。
const QUAKE_DURATION = 0.3
const QUAKE_FREQUENCY = Vector2(19, 27)

# 火焰噴發：撞擊瞬間上升高度與方塊大小額外放大的比例。
const FLARE_DURATION = 0.4
const FLARE_RISE = 1.4
const FLARE_SIZE = 0.8

# 撞擊碎片：火焰色方塊帶重力與旋轉。撞頂時由上緣兩端沿天花板向左右噴出並以 CEILING_DEBRIS_DROP 往下偏，
# 畫在數字前方；落地時由著地的角向上噴出，畫在數字後方。SPREAD 為以噴出方向為中心的散開角度。
# DEBRIS_COUNT 依表演等級設定，銀河炸開的碎片多於全像彩虹。
const CEILING_DEBRIS_COUNT = {Tier.HOLOGRAPHIC: 36, Tier.GALAXY: 80}
const CEILING_DEBRIS_SPEED = Vector2(320, 640)
const CEILING_DEBRIS_SPREAD = 0.45
const CEILING_DEBRIS_DROP = 0.3
const FLOOR_DEBRIS_COUNT = {Tier.HOLOGRAPHIC: 10, Tier.GALAXY: 20}
const FLOOR_DEBRIS_SPEED = Vector2(140, 300)
const FLOOR_DEBRIS_SPREAD = 1.0
const DEBRIS_GRAVITY = 1500.0
const DEBRIS_LIFETIME = Vector2(0.3, 0.6)
const DEBRIS_SIZE = Vector2(6, 14)
const DEBRIS_SPIN = 14.0

# 全像彩虹填色與火焰的共用漸強進度，以跑分佔本次最終分數的比例計算；填色外觀由 score_fill_config 管理，銀河轉場由 galaxy_transition_config 管理。
const ENERGY_START = 0.20
const ENERGY_FULL = 0.50

# 火焰由多層重疊方塊組成，參考 gameplay.png；各組由後往前繪製，最前方為主體。
# 依序為：頂端飄散的小方點、頂冠、從主體頂緣露出的色帶、包住數字的主體。
# FIRE_LAYERS_HOLOGRAPHIC 與 FIRE_LAYERS_GALAXY 依同樣順序逐層對應，層數相同；全像彩虹使用彩虹組，
# 銀河撞頂換成銀河後，各層的顏色與數值在 FIRE_BLEND_DURATION（galaxy_transition_config）內由彩虹組漸變到銀河組。
# bottom／top：滿能量時方塊出發與升到頂的高度，以字高為單位，0 為數字字底、1 為字頂；漸強期間整團火焰以字底為基準等比例縮放。
# width：分布寬度相對整串數字的比例；count：方塊數；size：邊長範圍（像素）；shrink：升到頂時相對初始邊長的比例。
# lifetime：速度倍率為 1 時上升一次的秒數範圍；acceleration：上升位移為壽命進度的次方，越大底部越慢、上方越快。
# spin：每秒轉動弧度範圍，方向隨機；spread：升到頂時的橫向偏移範圍（像素）。
# FIRE_SPEED_HOLOGRAPHIC 與 FIRE_SPEED_GALAXY 為兩組火焰上升與轉動的速度倍率，漸變期間跟著顏色一起過渡。
# FIRE_EMERGE 與 FIRE_FADE 為方塊在底部長出、到頂縮小消失各佔的壽命比例。
const FIRE_SPEED_HOLOGRAPHIC = 0.7
const FIRE_SPEED_GALAXY = 1.8
const FIRE_LAYERS_HOLOGRAPHIC = [
	{"color": Color("ffbe3d"), "bottom": 1.1, "top": 2.8, "width": 0.9, "count": 12, "size": Vector2(5, 11),
		"shrink": 0.6, "lifetime": Vector2(0.5, 0.9), "acceleration": 1.3, "spin": Vector2(3.0, 6.0), "spread": 30.0},
	{"color": Color("ffbe3d"), "bottom": 1.0, "top": 2.0, "width": 1.0, "count": 40, "size": Vector2(20, 55),
		"shrink": 0.4, "lifetime": Vector2(0.5, 0.85), "acceleration": 1.6, "spin": Vector2(1.6, 3.4), "spread": 18.0},
	{"color": Color("eb5e28"), "bottom": 0.8, "top": 1.4 , "width": 1.0, "count": 34, "size": Vector2(20, 70),
		"shrink": 0.5, "lifetime": Vector2(0.55, 0.9), "acceleration": 1.5, "spin": Vector2(1.0, 2.2), "spread": 14.0},
	{"color": Color("9e241b"), "bottom": 0.5, "top": 1.1, "width": 1.17, "count": 50, "size": Vector2(20, 75),
		"shrink": 0.6, "lifetime": Vector2(0.7, 1.2), "acceleration": 1.8, "spin": Vector2(0.3, 0.9), "spread": 10.0},
]

const FIRE_LAYERS_GALAXY = [
	{"color": Color("fff6cc"), "bottom": 1.1, "top": 2.8, "width": 0.9, "count": 12, "size": Vector2(5, 11),
		"shrink": 0.6, "lifetime": Vector2(0.5, 0.9), "acceleration": 1.3, "spin": Vector2(3.0, 6.0), "spread": 30.0},
	{"color": Color("fff6cc"), "bottom": 1.0, "top": 2.0, "width": 1.0, "count": 40, "size": Vector2(20, 55),
		"shrink": 0.4, "lifetime": Vector2(0.5, 0.85), "acceleration": 1.6, "spin": Vector2(1.6, 3.4), "spread": 18.0},
	{"color": Color("ffd15c"), "bottom": 0.8, "top": 1.4 , "width": 1.0, "count": 34, "size": Vector2(20, 70),
		"shrink": 0.5, "lifetime": Vector2(0.55, 0.9), "acceleration": 1.5, "spin": Vector2(1.0, 2.2), "spread": 14.0},
	{"color": Color("d97724"), "bottom": 0.5, "top": 1.1, "width": 1.17, "count": 50, "size": Vector2(20, 75),
		"shrink": 0.6, "lifetime": Vector2(0.7, 1.2), "acceleration": 1.8, "spin": Vector2(0.3, 0.9), "spread": 10.0},
]
const FIRE_EMERGE = 0.08
const FIRE_FADE = 0.2
const FIRE_INITIAL_ANGLE = Vector2(-PI, PI)
