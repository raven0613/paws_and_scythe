extends RefCounted

# 貓牌發動：卡片放大、旋轉、透視傾斜並帶角度抖動，同時從卡片中央拋出數字標籤。
# 標籤到位時目標開始跑數字，跑完 COUNT_DURATION 後卡片停留 RELEASE_HOLD，再補間收回，標籤同時縮小消失。
# 沒有數字的發動只播放卡片動作，目標在標籤到位的同一時間開始跑。
const LAYER = 30
const COUNT_DURATION = 0.25
const RELEASE_HOLD = 0.01

# 卡片姿態：OFFSET 為放大後卡片中心相對原本貓牌中心的位移（像素，y 向下），放大時移過去、收回時移回原位。
# SHADOW_OFFSET 為發動時影子相對卡面的位置（卡片原尺寸的像素），隨放大由場景設定的右下位置移過去，收回時移回。
# 旋轉以弧度計，負值為逆時針。TILT.x 讓左側靠近鏡頭、TILT.y 讓上緣靠近鏡頭，
# PERSPECTIVE 為鏡頭到卡面的距離（像素），越小透視越強；TILT_MARGIN 為透視變形可超出卡片邊緣的繪製範圍。
# 放大以 POP_DURATION 瞬間完成並以 POP_OVERSHOOT 衝過頭；收回以 RETURN_EASE 補間（Godot ease 曲線，負值為慢進慢出）。
const CARD_OFFSET = Vector2(48, -12)
const CARD_SHADOW_OFFSET = Vector2(-2, 2)
const CARD_SCALE = 1.8
const CARD_ROTATION = -0.1
const CARD_TILT = Vector2(0.3, 0.11)
const CARD_PERSPECTIVE = 125.0
const CARD_TILT_MARGIN = 16.0
const CARD_POP_DURATION = 0.07
const CARD_POP_OVERSHOOT = 1.7
const CARD_RETURN_DURATION = 0.1
const CARD_RETURN_EASE = -2.0

# 卡片抖動：位移與角度同時抖動並在 SHAKE_DURATION 內衰減；頻率以每秒弧度計，依序為 x、y、角度。
const CARD_SHAKE_DURATION = 0.36
const CARD_SHAKE_OFFSET = Vector2(4, 3)
const CARD_SHAKE_ANGLE = 0.07
const CARD_SHAKE_FREQUENCY = Vector3(71, 59, 53)

# 數字標籤路徑：以放大傾斜後的卡片右上角為原點（像素，y 向下），跟隨卡片姿態但不受卡片抖動影響。
# 從卡片中央以拋物線飛向 WALL 並從無長到原尺寸，LAUNCH_ARC 為拋物線在中點高出直線的距離；
# 撞牆後等速彈向左下的 REBOUND，再彈向左上的 REST 減速到位。
const BADGE_WALL = Vector2(22, 10)
const BADGE_REBOUND = Vector2(2, 30)
const BADGE_REST = Vector2(-4, -6)
const BADGE_LAUNCH_ARC = 40.0
const BADGE_FLIGHT_DURATION = 0.2
const BADGE_REBOUND_DURATION = 0.06
const BADGE_SETTLE_DURATION = 0.09

# 標籤姿態：方塊飛行時由 LAUNCH_ROTATION 轉到 ROTATION；文字只跟隨相對 ROTATION 的轉動，到位後保持正向。
# 到位時在 LANDING_PEAK（佔 LANDING_DURATION 的比例）放大到 LANDING_SCALE 再縮回原尺寸，
# 同時以 LANDING_SWINGS 次來回旋轉 LANDING_ANGLE 並抖動 LANDING_SHAKE，兩者一起衰減；抖動頻率依序為 x、y。
# 收回時以 EXIT_OVERSHOOT 先微微脹大再縮小消失。
const BADGE_LAUNCH_ROTATION = -2.4
const BADGE_ROTATION = 0.52
const BADGE_LANDING_DURATION = 0.25
const BADGE_LANDING_PEAK = 0.15
const BADGE_LANDING_SCALE = 1.45
const BADGE_LANDING_ANGLE = 0.35
const BADGE_LANDING_SWINGS = 1.5
const BADGE_LANDING_SHAKE = Vector2(1, 1)
const BADGE_LANDING_FREQUENCY = Vector2(83, 67)
const BADGE_EXIT_DURATION = 0.16
const BADGE_EXIT_OVERSHOOT = 1.7

# 標籤外觀：主體方塊邊長固定，文字描邊後可超出方塊。
const BADGE_SIZE = 27.0
const BADGE_COLOR = Color("e0783d")
const BADGE_FONT_SIZE = 20
const BADGE_TEXT_COLOR = Color.WHITE
const BADGE_TEXT_OUTLINE = Color("14253c")
const BADGE_TEXT_OUTLINE_SIZE = 6

# 彩虹標籤：目標為 RAINBOW_TARGET（總分倍率）時，三個方塊改用由左上到右下的斜向彩虹漸層，漸層隨方塊一起旋轉。
# RAINBOW_COLORS 為柔和偏鮮豔的色標；RAINBOW_LIGHTEN 依主體、第一節、第二節排列，為往白色混合的比例，逐節變淺。
# GRADIENT_RESOLUTION 為漸層貼圖邊長（像素）。
const BADGE_RAINBOW_TARGET = "total"
const BADGE_RAINBOW_COLORS = [Color("f07167"), Color("f39a4f"), Color("f2c75c"), Color("8fcf7a"), Color("5fb3e0"), Color("a184de")]
const BADGE_RAINBOW_LIGHTEN = [0.0, 0.28, 0.5]
const BADGE_GRADIENT_RESOLUTION = 64

# 尾巴方塊：由前往後兩節，每節接在前一節後方，方塊大小與顏色逐節遞減變淺；ROTATIONS 為各節相對主體多轉的角度，與主體一起轉動。
# 整條尾巴以 REST_ANGLE（弧度，y 向下，約左下方）的斜線為中心：主體橫向移動時，第一節被推向移動的反側，
# 推彎角度為橫向速度乘 BEND（弧度／每秒像素），上限 BEND_LIMIT；到位時跟隨主體的來回旋轉擺動，幅度放大 SWING_GAIN 倍。
# 第二節跟隨第一節的方向，落後累積成波浪。間距為 REST_DISTANCE 加上主體遠離尾巴的速度乘 STRETCH（秒），
# 主體朝尾巴移動時間距擠短，最短為 MIN_DISTANCE。
# 方向與間距各自以彈簧追隨：STIFFNESS 越大跟得越緊，DAMPING 越小擺得越過頭、越 Q 彈。
# 軌跡以 STEP 固定步長預先計算到到位後 SETTLE_DURATION 秒。
const TAIL_SIZES = [22.0, 17.0]
const TAIL_COLORS = [Color("ffb359"), Color("ffdd83")]
const TAIL_ROTATIONS = [0.32, -0.73]
const TAIL_REST_ANGLE = 2.5
const TAIL_REST_DISTANCE = [8.0, 8.0]
const TAIL_MIN_DISTANCE = 3.0
const TAIL_STRETCH = 0.02
const TAIL_BEND = 0.001
const TAIL_BEND_LIMIT = 0.7
const TAIL_SWING_GAIN = 1.4
const TAIL_ANGLE_STIFFNESS = [900.0, 700.0]
const TAIL_ANGLE_DAMPING = [22.0, 20.0]
const TAIL_DISTANCE_STIFFNESS = [420.0, 300.0]
const TAIL_DISTANCE_DAMPING = [14.0, 11.0]
const TAIL_STEP = 1.0 / 240.0
const TAIL_SETTLE_DURATION = 1.0
