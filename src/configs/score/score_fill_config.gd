extends RefCounted

enum Mode { GALAXY, HOLOGRAPHIC }
# GALAXY：銀河；HOLOGRAPHIC：柔和全像彩虹。
const MODE = Mode.HOLOGRAPHIC

# 兩種填色共用霧狀流場；速度為每秒向左移動的畫面像素。
# SPATIAL_SCALE 越大，雲霧越細；WARP 控制扭曲程度。
# EVOLUTION_SPEED 控制局部翻湧；CONTRAST 與 BRIGHTNESS 控制明暗層次。
const GALAXY_FLOW_SPEED = 155.0
const GALAXY_SPATIAL_SCALE = 0.018
const GALAXY_WARP = 1.4
const GALAXY_EVOLUTION_SPEED = 0.22
const GALAXY_CONTRAST = 1.6
const GALAXY_BRIGHTNESS = 1.0
# 深空至明亮雲霧，依序排列。
const GALAXY_COLORS = [
	Color("040924"), Color("182c7a"), Color("6835b8"),
	Color("c74ca3"), Color("f5c6e8"),
]
const GALAXY_VIOLET = Color("7863ac")
const GALAXY_VIOLET_AMOUNT = 0.18
# 撞擊碎片取自目前填色：銀河取 GALAXY_COLORS 從此索引起的亮色，加上星點色與紫色；全像彩虹取整組色盤。
const GALAXY_DEBRIS_FROM = 2

const HOLOGRAPHIC_FLOW_SPEED = 180.0
const HOLOGRAPHIC_SPATIAL_SCALE = 0.014
const HOLOGRAPHIC_WARP = 1.5
const HOLOGRAPHIC_EVOLUTION_SPEED = 0.25
const HOLOGRAPHIC_CONTRAST = 1.15
const HOLOGRAPHIC_BRIGHTNESS = 1.0
# 色盤循環次數與亮部的柔白光澤比例。
const HOLOGRAPHIC_COLOR_CYCLES = 1.6
const HOLOGRAPHIC_SHEEN = 0.1
# 循環的明亮全像色盤；首尾相同，霧狀色塊連續交融。
const HOLOGRAPHIC_COLORS = [
	Color("76a4fa"), Color("9d6ef5"), Color("f577bf"), Color("fa9064"),
	Color("f7d954"), Color("6ee084"), Color("4fd2ea"), Color("76a4fa"),
]

# 銀河星點使用獨立座標流動；大小與格距為畫面像素。
const STAR_FLOW_SPEED = 24.0
const STAR_CELL_SIZE = 22.0
# 每個格子生成星點的機率，以及星點半徑的最小／最大值。
const STAR_DENSITY = 0.48
const STAR_RADIUS = Vector2(0.55, 1.15)
const STAR_BRIGHTNESS = 0.85
const STAR_COLOR = Color("d3ebff")
# 閃爍速度為弧度／秒，幅度為亮度下降比例。
const STAR_TWINKLE_SPEED = 1.4
const STAR_TWINKLE_AMOUNT = 0.16
# 遠層相對近層的速度、尺寸、亮度與格距。
const STAR_FAR_SPEED_RATIO = 0.55
const STAR_FAR_SIZE_RATIO = 0.65
const STAR_FAR_BRIGHTNESS_RATIO = 0.55
const STAR_FAR_CELL_RATIO = 1.4

const PALETTE_RESOLUTION = 256
