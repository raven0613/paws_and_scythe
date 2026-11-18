extends RefCounted

# 商店畫面：LAYER 為商店圖層，商店與過關獎勵開啟期間，貓牌區與頂部資訊列提升到 FRONT_LAYER 顯示在遮罩上方。
const LAYER = 90
const FRONT_LAYER = 105
const SECTION_TITLES = ["貓牌", "轉換牌／任務單／貓點心", "卡包"]
const BUY_TEXT = "$%d 購買"
const FULL_TEXT = "已達上限"
const SOLD_TEXT = "已售出"
const REROLL_TEXT = "重骰 $%d"
const NEXT_TEXT = "下一關"
const OWNED_TEXT = "貓牌 %d / %d"
const RARITY_COLORS = {"R": Color("9fc3e8"), "SR": Color("d59cf0"), "SSR": Color("ffd05a")}
const SECTION_TITLE_SIZE = 14
const RARITY_SIZE = 12
const BUTTON_SIZE = 12
const ACTION_BUTTON_SIZE = 16
const OWNED_SIZE = 12
# 每區格子水平置中排列，格子之間間隔 SLOT_GAP；格子內卡片下方間隔 BUTTON_GAP 放購買按鈕。
const SLOT_SIZE = Vector2(96, 150)
const SLOT_GAP = 16.0
const SLOT_TOP = 30.0
const RARITY_HEIGHT = 16.0
const BUTTON_GAP = 6.0
const BUTTON_HEIGHT = 26.0

# 進場：三區依序從下方 ENTER_OFFSET 以 Expo Out 衝入，間隔 ENTER_STAGGER；衝過頭 BRAKE_OVERSHOOT 後
# 在 BRAKE_DURATION 內煞回原位，同時壓成 LAND_SQUASH 再回彈。抵達後區內商品依序往上跳 HOP_HEIGHT，間隔 HOP_STAGGER。
const ENTER_OFFSET = Vector2(0, 420)
const ENTER_TILT = 0.05
const ENTER_STAGGER = 0.1
const ENTER_DURATION = 0.34
const BRAKE_OVERSHOOT = 12.0
const BRAKE_DURATION = 0.18
const LAND_SQUASH = Vector2(1.04, 0.94)
const LAND_DURATION = 0.36
const HOP_HEIGHT = 12.0
const HOP_DURATION = 0.28
const HOP_STAGGER = 0.07
# 停留時商品以 IDLE_PERIOD 為週期上下浮動 IDLE_AMPLITUDE，相鄰商品相位差 IDLE_PHASE_STEP 形成波浪，
# 浮動幅度在 IDLE_FADE 秒內漸入漸出。
const IDLE_AMPLITUDE = 2.5
const IDLE_PERIOD = 2.2
const IDLE_PHASE_STEP = 0.7
const IDLE_FADE = 0.4
# 離場：三區依序以 Back In 往下掉出，間隔 EXIT_STAGGER。
const EXIT_OFFSET = Vector2(0, 460)
const EXIT_DURATION = 0.3
const EXIT_STAGGER = 0.06

# 購買：卡片先放大到 LIFT_SCALE，再沿高於兩端中點 FLIGHT_ARC 的弧線旋轉 FLIGHT_SPIN 飛到貓牌區；
# 重骰：貓牌翻面收起 FLIP_DURATION，換上新貓牌後翻回並依序跳動。按鈕與空出的格子以 POP 彈跳。
const LIFT_SCALE = 1.25
const LIFT_DURATION = 0.12
const FLIGHT_DURATION = 0.46
const FLIGHT_ARC = 110.0
const FLIGHT_SPIN = TAU
const FLIGHT_LAYER = 117
const FLIP_DURATION = 0.13
const POP = {"rise": 0.1, "settle": 0.4, "shake": 0.36, "tilt": 0.16, "cycles": 4.0, "decay": 1.6}
const BUTTON_POP_SCALE = 1.2
