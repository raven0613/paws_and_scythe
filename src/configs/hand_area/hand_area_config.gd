extends RefCounted

const Rules = preload("res://src/configs/gameplay/game_rules.gd")

const MIN_CARD_COUNT: int = 0
const DEFAULT_CARD_COUNT: int = Rules.HAND_LIMIT
const MAX_CARD_COUNT: int = Rules.MAX_HAND_LIMIT
const CARD_GAP: int = 4
const CARD_START_X: int = 16
const RIGHT_PADDING: int = 16
const BACKGROUND_EDGE_WIDTH: int = 16
const SELECTED_OFFSET = 14.0
# 出牌或棄牌後補位：仍在手上的牌由最靠近空位的一張開始，每隔 SHIFT_INTERVAL 依序以 Cubic Out 在 SHIFT_DURATION 內滑向新槽位，
# 底板右緣跟隨最後一張移動的牌收回。撤銷出牌時讓位的各張同時移動，時間由 action_animation_config 的 UNDO_HAND_SHIFT_DURATION 控制。
const SHIFT_DURATION = 0.18
const SHIFT_INTERVAL = 0.04
# 手牌 Hover：未選取的牌在 HOVER_DURATION 內以 Back Out 上浮 HOVER_LIFT，選取中的牌原地呼吸一次（參數見 playing_card/card_hover_config.gd），
# 兩者都拉到最上層並依滑鼠位置透視傾斜，滑鼠所在的一側往後壓。停在牌上點擊選取時，浮起在 HOVER_RELEASE_DURATION 內收回並呼吸一次。
# HOVER_TILT 為滑鼠在牌緣時左右（x）與上下（y）的最大傾斜弧度，HOVER_PERSPECTIVE 為鏡頭到牌面的距離（像素），越小透視越強；
# 傾斜以每秒 HOVER_TILT_FOLLOW 的速率平滑跟隨。離開時在 HOVER_RELEASE_DURATION 內以 Quad Out 歸位並回正。
# Hover 中位於 HOVER_LAYER，歸位中位於 HOVER_RELEASE_LAYER。
const HOVER_LIFT = 8.0
const HOVER_DURATION = 0.2
const HOVER_TILT = Vector2(0.3, 0.3)
const HOVER_PERSPECTIVE = 260.0
const HOVER_TILT_FOLLOW = 14.0
const HOVER_RELEASE_DURATION = 0.16
const HOVER_LAYER = 3
const HOVER_RELEASE_LAYER = 2
