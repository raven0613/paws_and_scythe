extends RefCounted

# 牌型亮相：得分的 combo 條依清單順序每隔 ROW_INTERVAL 接續聚焦，聚焦沿用 Hover 的放大、抖動與推開鄰列。
const ROW_INTERVAL = 0.2
# 場上對應的牌沿牌型路徑每隔 CARD_INTERVAL 接續浮起，RISE_DURATION 內以 Back Out 轉到扇形姿態。
const CARD_INTERVAL = 0.04
const RISE_DURATION = 0.18
# 扇形以牌組中央為零度向兩側展開，相鄰兩張相差 FAN_STEP 弧度，首尾總角度不超過 FAN_MAX_SPREAD。
const FAN_STEP = 0.01
const FAN_MAX_SPREAD = 0.62
# 每張沿自己旋轉後的上方位移 LIFT，位移量依 ±LIFT_JITTER 的比例隨機增減，形成不規則扇形。
const LIFT = 8.0
const LIFT_JITTER = 0.2
# 最後一張到位後全組停留 HOLD_DURATION，再於 RETURN_DURATION 內補間回原本位置與角度；收回開始時銜接下一段。
const HOLD_DURATION = 0.14
const RETURN_DURATION = 0.22
# 牌浮起到收回原位期間的圖層：第一組為 CARD_LAYER，之後每組加一，越晚亮相的組位於越上層。
const CARD_LAYER = 15
