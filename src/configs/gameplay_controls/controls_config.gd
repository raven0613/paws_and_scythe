@tool
extends RefCounted

const ICON_COLOR = Color("6a98e8")
const MONEY_COLOR = Color("eec445")
const DISABLED_ALPHA = 0.35
const HOVER_BRIGHTNESS = 1.2
const FONT_SIZE = 16
const BOARD_COUNT_FORMAT = "%d/%d"
const HOVER_CAPTIONS = {
	&"auto": "自動追蹤牌陣",
	&"reset": "框住全部場上卡牌",
	&"zoom_in": "拉近",
	&"zoom_out": "拉遠",
}
