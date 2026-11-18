extends RefCounted

const CARD_SIZE = Vector2(73, 92)
const ACTIVE_COLOR = Color("ffe6a0")
const REORDER_DURATION = 0.18
# 貓牌 Hover：大小與位置維持原樣，依滑鼠位置透視傾斜，滑鼠所在的一側往後壓。
# HOVER_TILT 為滑鼠在牌緣時左右（x）與上下（y）的最大傾斜弧度，HOVER_PERSPECTIVE 為鏡頭到卡面的距離（像素），越小透視越強；
# 傾斜以每秒 HOVER_TILT_FOLLOW 的速率平滑跟隨，離開時在 HOVER_RELEASE_DURATION 內以 Quad Out 回正。
const HOVER_TILT = Vector2(0.3, 0.3)
const HOVER_PERSPECTIVE = 260.0
const HOVER_TILT_FOLLOW = 14.0
const HOVER_RELEASE_DURATION = 0.16
const CHOICE_SIZE = Vector2(312, 78)
const CHOICE_COLUMNS = 3
const PICKER_SIZE = Vector2(1010, 580)
const CHOICE_FONT_SIZE = 14
const DESCRIPTION_FONT_SIZE = 12
const TITLE_FONT_SIZE = 24
const TARGET_NAMES = {"group": "牌型分數", "subtotal": "總分", "multiplier": "Combo 倍率", "total": "總分"}
const PICKER_TITLE = "測試入口：選擇貓牌"
const PICKER_DESCRIPTION = "複選 0～{limit} 張 / 同名限一張 / 以所選貓牌從 Lv 1 重新開始"
const PICKER_COUNT = "已選 {count} / {limit}"
const START_TEXT = "重新開始"
const CANCEL_TEXT = "取消"
const REPLAY_TEXT = "額外計分"
const CURRENT_AMOUNT_TEXT = "目前為 +%s"
const CURRENT_AMOUNT_MEASURES = ["settlements", "operations", "discards_used", "discards_left"]
const SELECTION_FLOW = "%s / 最高分牌型保留得分與 Combo"
const EXCLUSION_TEXT = "%s：此組得分與 Combo 為零"
