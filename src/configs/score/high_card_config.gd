extends RefCounted

# 高牌保底 +N：各張新出高牌依牌陣閱讀順序每隔 POP_INTERVAL 跳出，位置在該牌上緣中央上方 GAP 處，以底部中央為縮放基準。
# 每個 +N 在 GROW_DURATION 內以 Cubic Out 從零放大到原尺寸，接著在 SPRING_DURATION 內上下彈簧震動 SPRING_CYCLES 次，
# 振幅 SPRING_AMPLITUDE 像素依 SPRING_DECAY_POWER 衰減；往上時拉高變窄、往下時壓扁變寬，形變比例為 SPRING_STRETCH。
# 彈完時中央接續加上該張點數，中間各段跑分長度等於 POP_INTERVAL，最後一張使用 score_feedback_config 的 COUNT_DURATION。
# 中央加完後，所有 +N 隨中央到位回饋在 SHRINK_DURATION 內以 Back In 縮到消失。
const POP_INTERVAL = 0.08
const GROW_DURATION = 0.12
const SPRING_DURATION = 0.18
const SPRING_CYCLES = 3.0
const SPRING_AMPLITUDE = 7.0
const SPRING_DECAY_POWER = 1.5
const SPRING_STRETCH = 0.12
const SHRINK_DURATION = 0.16
# +N 的字級固定，不隨牌陣縮放；GAP 為描邊下緣到牌上緣的距離。LAYER 位於牌陣（-2）上方、黑邊與固定介面（0）下方。
const GAP = 4.0
const LAYER = -1
const TEXT_FORMAT = "+%d"
const FONT_SIZE = 26
const TEXT_COLOR = Color.WHITE
const OUTLINE_COLOR = Color("14253c")
const OUTLINE_SIZE = 8
