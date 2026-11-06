@tool
extends RefCounted

const DETAILS_TITLE_FORMAT = "%s · %d 張"

const FRAME_PATHS: PackedStringArray = [
	"res://src/assets/combo_frame_01.png",
	"res://src/assets/combo_frame_02.png",
	"res://src/assets/combo_frame_03.png",
]
const FRAME_COLOR = Color("6082b5")
const TEXT_COLOR = Color("d8e5fa")
const SCORE_COLOR = Color("fff0c2")
const SHADOW_COLOR = Color("151c28")
const SHADOW_OFFSET = Vector2(3, 3)
const SLICE_MARGIN = 8
const TEXT_PADDING = Vector2(12, 4)
const FONT_SIZE = 12
const ROW_GAP = 4.0
const OFFSET_MIN = -8
const OFFSET_MAX = 4
const INITIAL_SEQUENCE_LENGTH = 32
const EDITOR_SEED = 72603
const TEST_SEED_COUNT = 32
const ENTER_OFFSET = 24.0
const ENTER_DURATION = 0.22
const FADE_DURATION = 0.07

const EXCLUDED_COLOR = Color("777f92")
