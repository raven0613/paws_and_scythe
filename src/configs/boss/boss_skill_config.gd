extends RefCounted

const LEVELS_PER_SKILL: int = 3
const PREVIEW_SKILLS: PackedStringArray = ["2 COMBO以下不計分"]
const FRONT_COLOR: Color = Color("b54325")
const BACK_COLOR: Color = Color("541b12")
const HIDDEN_COLOR: Color = Color(0.06, 0.015, 0.01, 0)
const LIGHT_ON: Color = Color("f47846")
const LIGHT_OFF: Color = Color("813020")
const LIGHT_HIGHLIGHT: Color = Color("ffd09b")
const FRONT_POSITION: Vector2 = Vector2(0, 0)
const BACK_POSITION: Vector2 = Vector2(10, 13)
const ENTRY_POSITION: Vector2 = Vector2(16, 36)
const EXIT_POSITION: Vector2 = Vector2(-5, -27)
const FRONT_ROTATION: float = 0.0
const BACK_ROTATION: float = 0.045
const ENTRY_ROTATION: float = 0.15
const EXIT_ROTATION: float = -0.10
const FULL_LIGHT_HOLD: float = 0.25
const SWITCH_DURATION: float = 0.65
const EXIT_DURATION: float = 0.45
const ENTRY_DELAY: float = 0.12
