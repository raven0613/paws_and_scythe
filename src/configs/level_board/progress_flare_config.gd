extends RefCounted

# 高分表演的進度條入帳：結算最後粒子抵達左上、累積分數跑 LEVEL_COUNT_DURATION（score_feedback_config.gd）期間，
# 進度條快速震動並發光；全像彩虹使用 HOLOGRAPHIC、銀河使用較誇張的 GALAXY。
# 震動與放大：在 ATTACK 秒內增強到滿幅，放大以 Back Out 衝到 scale；跑分結束前 RELEASE 秒內震動衰減歸零、放大以 Cubic Out 縮回原尺寸。
# 發光：在 GLOW_RISE 秒內亮到最高並維持到跑分結束，結算結束後在 GLOW_FADE 秒內淡出。
const ATTACK = 0.06
const RELEASE = 0.14
const GLOW_RISE = 0.1
const GLOW_FADE = 0.45

# 霓虹燈管：進度條本身的填色與邊框往 CORE_COLOR 混合形成亮芯；外暈沿進度條的圓角外形向外擴散並淡出，最內側為 HALO_COLOR。
const CORE_COLOR = Color("F4F9FF")
const HALO_COLOR = Color("A6CBE8")

# shake 為位移震幅（像素，x、y），tilt 為旋轉震幅（弧度），frequency 為震動頻率（每秒弧度，依序 x、y、角度）；
# scale 為放大倍率，1.0 維持原尺寸；core 為填色與邊框混入亮芯的比例；halo_size 為外暈擴散寬度（像素），halo_alpha 為外暈最內側的不透明度。
const HOLOGRAPHIC = {
	"shake": Vector2(2.5, 2.0), "tilt": 0.015, "frequency": Vector3(83.0, 71.0, 59.0), "scale": 1.0,
	"core": 0.55, "halo_size": 8, "halo_alpha": 0.75,
}
const GALAXY = {
	"shake": Vector2(3.5, 2.5), "tilt": 0.03, "frequency": Vector3(97.0, 83.0, 67.0), "scale": 1.2,
	"core": 0.9, "halo_size": 14, "halo_alpha": 1.0,
}
