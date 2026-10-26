@tool
extends RefCounted

const INITIAL_CELL = Vector2i.ZERO
const NEIGHBORS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
const CARD_SIZE = Vector2(73, 92)
const CARD_GAP = Vector2(4, 4)
const CELL_STEP = CARD_SIZE + CARD_GAP
const VIEW_PADDING = 12.0
const DEFAULT_ZOOM = 1.0
const FIT_DURATION = 0.18
const MIN_ZOOM = 0.12
const MAX_ZOOM = 2.0
const ZOOM_STEP = 1.12
const BUTTON_ZOOM_DURATION = 0.18
const TRACKPAD_ZOOM_SENSITIVITY = 0.08
const TOUCH_TAP_DISTANCE = 12.0
const GROUP_HOVER_SCALE = 1.07
const GROUP_HOVER_DURATION = 0.14
