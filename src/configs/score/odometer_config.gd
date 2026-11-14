extends RefCounted

const GROUP_NAME = &"score_odometer"
const RADIX = 10
const MULTIPLIER_MIN_DECIMALS = 1
const MULTIPLIER_MAX_DECIMALS = 2
const ROLL_START = 0.2
# 每位數平均每秒轉過的格數超過 READABLE_RATE 時，改以 SPIN_RATE 沿計數方向等速捲動，
# 並在轉速回到可讀範圍時精確接上實際輪位。
const READABLE_RATE = 14.0
const SPIN_RATE = 18.0
const DETENT_SCALE = Vector2(0.12, -0.1)
const DETENT_PORTION = 0.22
const DIGIT_PADDING = 1.0
const VERTICAL_PADDING = 2.0
const DETENT_DURATION = 0.075
