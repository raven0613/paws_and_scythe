extends RefCounted

# 過關獎勵畫面：顯示圖層、文字與字級。
const LAYER = 100
const TITLE = "Lv %d 過關！"
const SCORE_TEXT = "%s / %s 分"
const ROW_NAMES = {"base": "過關獎勵", "cat": "貓牌", "speed": "速通獎勵", "quest": "任務單", "interest": "利息"}
const ROW_DETAILS = {"speed": "剩餘 %d 次結算", "interest": "持有 $%d"}
const AMOUNT_FORMAT = "+$%d"
const TOTAL_NAME = "本關收入"
const SHOP_TEXT = "進入商店"
const TITLE_SIZE = 28
const SCORE_SIZE = 12
const ROW_SIZE = 16
const DETAIL_SIZE = 12
const TOTAL_SIZE = 26
const BUTTON_SIZE = 16
const ROW_WIDTH = 288.0
const ROW_HEIGHT = 30.0
const AMOUNT_WIDTH = 80.0
const DETAIL_GAP = 8.0

# 進場：遮罩淡入，面板從上方 DROP_OFFSET 以 Expo Out 落下並帶 DROP_TILT 傾角，
# 落地瞬間壓成 LAND_SQUASH 再以 Elastic 回彈；標題從 0 放大到 TITLE_POP_SCALE 後回彈並衰減抖動。
# 所有彈出共用 POP：rise 放大、settle 回彈、shake 抖動時間，tilt、cycles、decay 為旋轉抖動幅度、次數與衰減。
const SHADE_FADE = 0.2
const DROP_OFFSET = Vector2(0, -320)
const DROP_TILT = -0.12
const DROP_DURATION = 0.38
const LAND_SQUASH = Vector2(1.08, 0.9)
const LAND_DURATION = 0.4
const TITLE_DELAY = 0.12
const TITLE_POP_SCALE = 1.5
const POP = {"rise": 0.1, "settle": 0.42, "shake": 0.4, "tilt": 0.14, "cycles": 4.0, "decay": 1.6}

# 明細列：每列從左側 ROW_SLIDE 滑入並以 Back Out 煞停，金額跳出後噴出金幣飛進右上金錢；
# 列與列間隔 ROW_STAGGER，最後一列之後等待 COIN_SETTLE 讓金幣落定，再讓合計放大到 TOTAL_POP_SCALE。
const ROW_SLIDE = 90.0
const ROW_SLIDE_DURATION = 0.3
const ROW_STAGGER = 0.42
const AMOUNT_DELAY = 0.12
const AMOUNT_POP_SCALE = 1.8
const TOTAL_COUNT_DURATION = 0.28
const COIN_SETTLE = 0.45
const TOTAL_POP_SCALE = 1.9
const ZERO_ALPHA = 0.45

# 按鈕在合計之後彈出，停留時以 BREATH_PERIOD 週期在 1 與 BREATH_SCALE 之間呼吸；
# 點擊畫面時演出以 SKIP_SPEED 倍速播放；離場時面板以 Back In 往上飛出。
const BUTTON_DELAY = 0.3
const BREATH_SCALE = 1.06
const BREATH_PERIOD = 1.1
const SKIP_SPEED = 4.0
const EXIT_OFFSET = Vector2(0, -380)
const EXIT_DURATION = 0.3
