extends RefCounted

# 金錢數字：跳到新數值的時間為 COUNT_DURATION，同時從 POP_SCALE 以 Elastic 回彈；
# 增加時閃 GAIN_FLASH、減少時閃 SPEND_FLASH，在 FLASH_DURATION 內回到原色。
const COUNT_DURATION = 0.22
const POP_SCALE = 1.5
const POP_DURATION = 0.45
const GAIN_FLASH = Color("fff6c8")
const SPEND_FLASH = Color("ff7a6a")
const FLASH_DURATION = 0.32
# 金錢圖示隨數字放大回彈，並播放 ICON_SHAKE_CYCLES 次衰減旋轉抖動。
const ICON_POP_SCALE = 1.4
const ICON_TILT = 0.4
const ICON_SHAKE_CYCLES = 3.0
const ICON_SHAKE_DURATION = 0.34
const ICON_SHAKE_DECAY = 1.6

# 金幣飛行：每枚先以 Back Out 向外噴出 BURST_DURATION，再沿弧線加速飛入目標 TRAVEL_DURATION；
# 相鄰金幣間隔 STAGGER，數量依金額、最多 MAX_COINS 枚。翻面速度為每秒 SPIN_SPEED 弧度。
const COIN_LAYER = 118
const MAX_COINS = 12
const COIN_SIZE = 8.0
const COIN_MIN_WIDTH = 0.25
const COIN_COLOR = Color("eec445")
const COIN_EDGE = Color("8a5a12")
const COIN_SHINE = Color("fff6c8")
const BURST_RADIUS = Vector2(10.0, 30.0)
const BURST_DURATION = 0.16
const TRAVEL_DURATION = 0.42
const STAGGER = 0.045
const ARC_HEIGHT = 70.0
const SPIN_SPEED = 16.0
# 金幣抵達時在目標點擴散一圈光環。
const SPARK_DURATION = 0.2
const SPARK_RADIUS = 14.0
const SPARK_WIDTH = 2.0
const SPARK_SEGMENTS = 16
