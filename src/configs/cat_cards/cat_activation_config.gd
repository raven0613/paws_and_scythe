extends RefCounted

# 貓牌發動：卡片放大、旋轉、透視傾斜並帶角度抖動，同時從卡片中央拋出數字標籤。
# 標籤到位時目標開始跑數字，跑完 COUNT_DURATION 後卡片停留 RELEASE_HOLD，再補間收回，標籤同時縮小消失。
# 沒有數字的發動只播放卡片動作，目標在標籤到位的同一時間開始跑。
const LAYER = 30
const COUNT_DURATION = 0.38
const RELEASE_HOLD = 0.15

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
const CARD_RETURN_DURATION = 0.2
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
const BADGE_LANDING_DURATION = 0.3
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

# 尾巴方塊：由前往後兩節，每節接在前一節後方，方塊大小與顏色逐節遞減變淺；ROTATIONS 為各節相對主體多轉的角度，與主體一起轉動。
# 第一節的方向跟隨主體移動的反方向，速度低於 FOLLOW_SPEED 時逐漸轉回 REST_ANGLE（弧度，y 向下，約左下方）並隨主體轉動；
# 第二節跟隨第一節的方向。間距為 REST_DISTANCE 加上主體速度乘 STRETCH（秒），移動越快拉得越長。
# 方向與間距各自以彈簧追隨：STIFFNESS 越大跟得越緊，DAMPING 越小甩得越過頭；第二節追隨第一節，落後逐節累積形成甩鞭。
# 軌跡以 STEP 固定步長預先計算到到位後 SETTLE_DURATION 秒。
const TAIL_SIZES = [22.0, 17.0]
const TAIL_COLORS = [Color("ffb359"), Color("ffdd83")]
const TAIL_ROTATIONS = [0.32, -0.73]
const TAIL_REST_ANGLE = 2.5
const TAIL_REST_DISTANCE = [8.0, 8.0]
const TAIL_STRETCH = 0.02
const TAIL_FOLLOW_SPEED = 120.0
const TAIL_ANGLE_STIFFNESS = [260.0, 420.0]
const TAIL_ANGLE_DAMPING = [17.0, 22.0]
const TAIL_DISTANCE_STIFFNESS = [420.0, 300.0]
const TAIL_DISTANCE_DAMPING = [14.0, 11.0]
const TAIL_STEP = 1.0 / 240.0
const TAIL_SETTLE_DURATION = 1.0
