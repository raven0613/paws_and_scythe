extends RefCounted

# 各動作的飛行形變與落地回彈開關。
const DRAW_ENABLED = true
const PLACE_ENABLED = true
const DISCARD_ENABLED = true
const SWAP_ENABLED = true
const UNDO_PLACE_ENABLED = true
const UNDO_SWAP_ENABLED = true
const UNDO_DIG_ENABLED = true

# 臨界阻尼彈簧的反應速度；位置到站後固定。
const SPRING_RESPONSE = 8.0

# 速度伸縮：整張牌沿當下的移動方向拉長、垂直方向等比例變窄，面積不變。速度取牌中心在基準畫面中的可見速度（像素/秒），
# 達 FULL_SPEED 時沿移動方向拉長 MAX_STRETCH（0.25 為拉長 25%）；起飛加速時拉長，減速時跟著收回。
const FULL_SPEED = 3000.0
const MAX_STRETCH = 0.25
# 飛行傾身：牌面前緣往遠離鏡頭的方向壓低，速度達 FULL_SPEED 時傾斜 MAX_LEAN 弧度；
# LEAN_PERSPECTIVE 為鏡頭到牌面的距離（牌面原尺寸像素），越小透視越強。
const MAX_LEAN = 0.45
const LEAN_PERSPECTIVE = 220.0

# 離開桌面的高度：高度最高時牌面放大 LIFT_SCALE，陰影由原位再偏移 LIFT_SHADOW（牌面原尺寸像素）。
const LIFT_SCALE = 0.2
const LIFT_SHADOW = Vector2(7, 10)

# 落地回彈：到站後牌面先壓小 press，再以 cycles 次振盪 Q 彈回原尺寸，振幅依 decay 次方衰減，duration 秒後停穩；
# 到站時殘留的伸縮與傾身以同一振盪反向擺動後收回。放牌拍上盤面使用 PLACE_LANDING，其餘抵達目的地的動作使用 LIGHT_LANDING。
const PLACE_LANDING = {"duration": 0.20, "press": 0.14, "cycles": 1.5, "decay": 1.6}
const LIGHT_LANDING = {"duration": 0.20, "press": 0.05, "cycles": 0.75, "decay": 1.8}
