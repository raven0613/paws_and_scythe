extends RefCounted

# Hover 回饋，預設值與 combo 條 Hover 相同：進入時在 HOVER_SCALE_DURATION 內以 Back Out 放大到 HOVER_SCALE，
# 同時在 HOVER_SHAKE_DURATION 內播放衰減的位移與旋轉抖動，停留時維持放大；離開時在 HOVER_RELEASE_DURATION 內恢復。
const HOVER_SCALE = 1.25
const HOVER_SCALE_DURATION = 0.18
const HOVER_SHAKE_DURATION = 0.25
const HOVER_SHAKE = Vector2(6.0, 4.0)
const HOVER_TILT = 0.25
const HOVER_CYCLES = 2.5
const HOVER_VERTICAL_CYCLES = 4.0
const HOVER_DECAY_POWER = 2.0
const HOVER_RELEASE_DURATION = 0.16
const HOVER_LAYER = 1

# 左右按鈕依放大後的寬度讓出 HOVER_GAP 間隙，於 PUSH_DURATION 內推開；每側 HOVER_DISTURB_COUNT 顆依距離接續疊加擾動，
# 最近一顆位移 DISTURB_DISTANCE、旋轉 DISTURB_TILT，每遠一顆乘上 DISTURB_FALLOFF。
const HOVER_GAP = 6.0
const HOVER_DISTURB_COUNT = 3
const PUSH_DURATION = 0.25
const DISTURB_DISTANCE = 4.0
const DISTURB_TILT = 0.025
const DISTURB_INTERVAL = 0.08
const DISTURB_DURATION = 0.5
const DISTURB_CYCLES = 1.75
const DISTURB_DECAY_POWER = 2.0
const DISTURB_FALLOFF = 0.65

# 水面把外框當成箱子：Hover 進入、離開與被左右推動時各甩一下，水面以阻尼彈簧左右傾斜擺盪並疊上碎浪，再慢慢回到平靜。
# 甩動強度 1 時水面兩端最大高低差約為 SLOSH_TILT 倍按鈕高度；擺盪頻率 SLOSH_FREQUENCY 次／秒，阻尼比 SLOSH_DAMPING 越小平靜得越慢。
# 碎浪振幅為 SLOSH_CHOP_AMPLITUDE 倍按鈕高度乘上累積能量，能量上限 SLOSH_CHOP_MAX，依 SLOSH_CHOP_CALM 秒的時間常數衰減。
const SLOSH_TILT = 0.4
const SLOSH_FREQUENCY = 1.4
const SLOSH_DAMPING = 0.1
const SLOSH_CHOP_AMPLITUDE = 0.08
const SLOSH_CHOP_MAX = 1.5
const SLOSH_CHOP_CALM = 0.8
const SLOSH_CHOP_WAVELENGTH = 36.0
const SLOSH_CHOP_SPEED = 7.0
# 各時機的甩動強度：Hover 進入、離開縮回，以及被推開或回位的最近一顆鄰居，鄰居強度隨距離乘上 DISTURB_FALLOFF。
const SLOSH_ENTER_KICK = 1.0
const SLOSH_RELEASE_KICK = 0.7
const SLOSH_NEIGHBOR_KICK = 0.5
# 彈簧模擬的子步長與判定平靜的門檻。
const SLOSH_STEP = 1.0 / 120.0
const SLOSH_REST_EPSILON = 0.001

const HOVER_PROFILE = {
	"scale": HOVER_SCALE, "scale_duration": HOVER_SCALE_DURATION, "shake_duration": HOVER_SHAKE_DURATION,
	"shake": HOVER_SHAKE, "tilt": HOVER_TILT, "cycles": HOVER_CYCLES, "vertical_cycles": HOVER_VERTICAL_CYCLES,
	"decay_power": HOVER_DECAY_POWER, "release_duration": HOVER_RELEASE_DURATION, "layer": HOVER_LAYER,
}
# 橫向排列的擾動旋轉跟隨左右方向。
const DISTURB_PROFILE = {
	"falloff": DISTURB_FALLOFF, "interval": DISTURB_INTERVAL, "push_duration": PUSH_DURATION,
	"disturb_duration": DISTURB_DURATION, "cycles": DISTURB_CYCLES, "decay_power": DISTURB_DECAY_POWER,
	"distance": DISTURB_DISTANCE, "tilt": DISTURB_TILT, "lean_axis": Vector2.RIGHT,
}
