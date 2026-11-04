@tool
extends RefCounted

# 修改後重新執行遊戲；編輯器預覽可重新載入專案。
const NUMBER_PIXEL_ENABLED = false
const CHINESE_PIXEL_ENABLED = false

# 數字與拉丁字母取自 BM HANNA Pro；子集排除漢字以交由 Cubic 11 呈現。
const NUMBER_FONT = preload("res://src/assets/fonts/generated/PawsNumerals.ttf")
const CHINESE_FONT = preload("res://src/assets/fonts/Cubic_11.ttf")
const DEFAULT_FONT_SIZE = 12
const PIXEL_OVERSAMPLING = 1.0
const SMOOTH_OVERSAMPLING = 0.0
