extends RefCounted

# 點擊貓牌後在卡片下緣顯示賣出按鈕，按鈕以 POP 從零彈出；BUTTON_OVERLAP 為按鈕壓在卡片下緣的高度。
const SELL_TEXT = "賣出 $%d"
const SELL_FONT_SIZE = 12
const SELL_BUTTON_SIZE = Vector2(64, 22)
const BUTTON_OVERLAP = 14.0
const BUTTON_POP_SCALE = 1.25
# 賣出：卡片往上彈起 VANISH_LIFT_HEIGHT 並放大到 VANISH_LIFT_SCALE，再旋轉 VANISH_SPIN 縮小消失；
# 其餘貓牌接著以 SLIDE_DURATION 平滑移到新位置。
const VANISH_LIFT_SCALE = 1.3
const VANISH_LIFT_HEIGHT = 14.0
const VANISH_LIFT_DURATION = 0.14
const VANISH_SHRINK_DURATION = 0.24
const VANISH_SPIN = 2.4
const SLIDE_DURATION = 0.26
# 購買：貓牌從零彈出到 ARRIVAL_POP_SCALE 再回彈，同時旋轉抖動。
const ARRIVAL_POP_SCALE = 1.35
const POP = {"rise": 0.1, "settle": 0.42, "shake": 0.4, "tilt": 0.2, "cycles": 4.0, "decay": 1.6}
