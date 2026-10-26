@tool
extends RefCounted

const REFERENCE_SIZE = Vector2(1152, 648)
const BORDER_COLOR = Color("151c28")
const TOP_HEIGHT = 34.0
const BOTTOM_HEIGHT = 30.0
const LEFT_WIDTH = 37.0
const CLEAR_RIGHT_X = 883.0

# 斜邊以內、四邊都完整可見的區域，供背景密度驗證使用。
const CLEAR_RECT = Rect2(
	LEFT_WIDTH, TOP_HEIGHT,
	CLEAR_RIGHT_X - LEFT_WIDTH, REFERENCE_SIZE.y - TOP_HEIGHT - BOTTOM_HEIGHT
)
