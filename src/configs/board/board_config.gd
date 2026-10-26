@tool
extends RefCounted

const INITIAL_CELL = Vector2i.ZERO
const NEIGHBORS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
const CARD_SIZE = Vector2(73, 92)
const CARD_GAP = Vector2(4, 4)
const CELL_STEP = CARD_SIZE + CARD_GAP
const MAX_PLAYS_PER_TURN = 6
const VIEW_PADDING = 12.0
const DEFAULT_ZOOM = 1.0
const FIT_DURATION = 0.18
