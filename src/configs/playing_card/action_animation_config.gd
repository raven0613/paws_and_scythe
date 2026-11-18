extends RefCounted

const FLIGHT_LAYER = 20
# 放牌與撤銷出牌：離開桌面的高度在飛行進度 PLACE_APEX 時最高，之前快速升起、之後加速落下拍上目的地；
# 最高時牌面抬到上方牌高 PLACE_ARC_HEIGHT 倍的位置，牌面放大與陰影偏移見 flight_animation_config。
const PLACE_FLIGHT_DURATION = 0.26
const PLACE_ARC_HEIGHT = 0.25
const PLACE_APEX = 0.45
const UNDO_PLACE_DURATION = 0.24
# 讓位在回手飛行結束前完成，實際時間取兩者較短值。
const UNDO_HAND_SHIFT_DURATION = 0.18
const UNDO_SWAP_DURATION = 0.3
const UNDO_DIG_SPEED = 1.3
const SWAP_DURATION = 0.3
const SWAP_ARC_HEIGHT = 0.2
const SWAP_TILT = 0.08
const DIG_SHAKE_DURATION = 0.08
const DIG_SHAKE_CYCLES = 3.0
const DIG_SHAKE_WIDTH = 0.04
const DIG_SHAKE_TILT = 0.045
const DIG_EJECT_SPEED = 1.3
const DIG_SPEED = 1.0
const DIG_RISE_HEIGHT = 1.0 / 3.0
const DIG_APEX_TIME = 0.16
const DIG_SIDE_WIDTH = 1.0
const DIG_TILT = 0.24
const DIG_EXIT_MARGIN = 4.0
const DISCARD_DURATION = 0.32
const DISCARD_INTERVAL = 0.045
const DISCARD_TILT = -0.35
const DISCARD_FADE_START = 0.75
