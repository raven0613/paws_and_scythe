extends RefCounted

# 各動作的前角拉伸與到站形狀回彈開關。
const DRAW_ENABLED = true
const PLACE_ENABLED = true
const DISCARD_ENABLED = true
const SWAP_ENABLED = true
const UNDO_PLACE_ENABLED = true
const UNDO_SWAP_ENABLED = true
const UNDO_DIG_ENABLED = true

# 臨界阻尼彈簧的反應速度；位置到站後固定。
const SPRING_RESPONSE = 8.0
# 基準畫面中，達到最大拉伸的起終點距離。
const FULL_STRETCH_DISTANCE = 360.0
const MAX_STRETCH_RATIO = 0.08
const STRETCH_ATTACK = 0.18
const ARRIVAL_STRETCH = 0.6
# 回縮量相對於本次拉伸量，單次回縮後回復原形。
const RECOIL_RATIO = 0.08
const RECOIL_DURATION = 0.045
const RECOVER_DURATION = 0.065
