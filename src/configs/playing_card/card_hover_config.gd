extends RefCounted

# 場上牌與選取中手牌的 Hover 呼吸：滑鼠進入時卡面以自身中心在 BREATH_UP 內以 Quart Out 放大到 BREATH_SCALE，
# 再於 BREATH_DOWN 內以 Sine In Out 縮回原尺寸，每次進入播放一次。場上牌播放期間位於其他牌上層 BREATH_LAYER。
const BREATH_SCALE = 1.05
const BREATH_UP = 0.08
const BREATH_DOWN = 0.2
const BREATH_LAYER = 2
