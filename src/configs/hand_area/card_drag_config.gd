@tool
extends RefCounted

# 拖曳放牌：按住手牌移動超過 START_DISTANCE 像素開始拖曳，未超過就放開視為點選。
const START_DISTANCE = 6.0
# 拿起時以 Back Out 在 LIFT_DURATION 內浮起到離開桌面高度 1；牌面放大與陰影偏移沿用 flight_animation_config 的 LIFT_*。
# 游標鎖定待放格時牌面降到 TARGET_LIFT，像準備蓋下去；離開待放格時以同樣的補間升回 1。
const LIFT_DURATION = 0.18
const TARGET_LIFT = 0.55
# 牌以每秒 FOLLOW_SPEED 的指數速率追上游標，越大越緊貼。
const FOLLOW_SPEED = 30.0
# 擺動：依橫向速度（基準畫面像素/秒）乘 SWAY_PER_SPEED 弧度傾斜，上限 MAX_SWAY，以每秒 SWAY_FOLLOW 的速率平滑跟隨。
const SWAY_PER_SPEED = 0.00022
const MAX_SWAY = 0.22
const SWAY_FOLLOW = 14.0
# 吸附：游標與合法待放格中心的距離在 SNAP_RANGE 倍格子對角線以內時鎖定最近的一格，牌往該格中心靠攏 MAGNET 比例。
const SNAP_RANGE = 0.6
const MAGNET = 0.35
