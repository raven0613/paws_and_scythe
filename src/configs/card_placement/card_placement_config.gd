@tool
extends RefCounted

const INITIAL_HINT = "放置第一張牌"
const INITIAL_TOOLTIP = "選取手牌後，放置第一張牌"
const AVAILABLE_TOOLTIP = "將選取的手牌放在這裡"
const BASE_COLOR = Color("3c577d")
const FRAME_COLOR = Color("b1cff9")
const ACTIVE_COLOR = Color("e1efff")
const HOVER_COLOR = Color("54759c")
const HINT_FONT_SIZE = 12
const FADE_DURATION = 0.14
const HIDDEN_SCALE = Vector2(0.92, 0.92)
# 拖曳中被鎖定的待放格使用 Hover 配色，並以 Back Out 在 DROP_TARGET_DURATION 內放大到 DROP_TARGET_SCALE；解除時以同樣的補間縮回。
const DROP_TARGET_SCALE = 1.12
const DROP_TARGET_DURATION = 0.16
