extends RefCounted

const Rules = preload("res://src/configs/gameplay/game_rules.gd")

const MIN_CARD_COUNT: int = 0
const DEFAULT_CARD_COUNT: int = Rules.HAND_LIMIT
const MAX_CARD_COUNT: int = Rules.MAX_HAND_LIMIT
const CARD_GAP: int = 4
const CARD_START_X: int = 16
const RIGHT_PADDING: int = 16
const BACKGROUND_EDGE_WIDTH: int = 16
const SELECTED_OFFSET = 14.0
