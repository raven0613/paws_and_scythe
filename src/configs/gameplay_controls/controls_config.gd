@tool
extends RefCounted

const ICON_COLOR = Color("6a98e8")
const MONEY_COLOR = Color("eec445")
const DISABLED_ALPHA = 0.35
const HOVER_BRIGHTNESS = 1.2
const FONT_SIZE = 16
const BOARD_COUNT_FORMAT = "%d/%d"
# 場上張數達到容量上限時轉為警示色，每 BOARD_FULL_PERIOD 秒以 Sine In Out 在 BOARD_FULL_COLOR 與 BOARD_FULL_DIM_COLOR 之間呼吸閃爍一次。
const BOARD_FULL_COLOR = Color("ff7a6a")
const BOARD_FULL_DIM_COLOR = Color("ff7a6a", 0.3)
const BOARD_FULL_PERIOD = 1.6
# 剛滿格與滿格時嘗試拖曳手牌：張數以右緣為軸放大到 BOARD_ALERT_SCALE，在 BOARD_ALERT_DURATION 內以 Elastic Out 彈回，
# 同時旋轉抖動 BOARD_ALERT_CYCLES 次，最大角度 BOARD_ALERT_TILT 弧度，振幅依 BOARD_ALERT_DECAY 次方衰減。
const BOARD_ALERT_SCALE = 1.5
const BOARD_ALERT_DURATION = 0.5
const BOARD_ALERT_TILT = 0.22
const BOARD_ALERT_CYCLES = 3.0
const BOARD_ALERT_DECAY = 1.6
const HOVER_CAPTIONS = {
	&"auto": "自動追蹤牌陣",
	&"reset": "框住全部場上卡牌",
	&"zoom_in": "拉近",
	&"zoom_out": "拉遠",
}
