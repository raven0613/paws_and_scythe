extends RefCounted

const Feel = preload("res://src/configs/score/celebration_config.gd")

# 高分表演的背景扭曲，全像彩虹與銀河各一組，銀河較誇張；扭曲作用於周邊 UI 之上、暗角之下的畫面。
# 每次結算只在炸開的瞬間發出一次衝擊波：全像彩虹在撞頂時發出，銀河在反轉幀結束換成銀河時發出。

# 衝擊波：從數字中心擴散的扭曲環，環上的背景沿半徑方向被推擠，強度隨擴散衰減到 0。
# duration：擴散秒數；radius：最終半徑；width：環寬；radius 與 width 以畫面半高為 1；
# strength：環上背景的最大位移（像素）；aberration：環上紅藍色散的最大錯開距離（像素）。
const SHOCKWAVE = {
	Feel.Tier.HOLOGRAPHIC: {"duration": 0.15, "radius": 0.8, "width": 0.03, "strength": 10.0, "aberration": 0.5},
	Feel.Tier.GALAXY: {"duration": 0.25, "radius": 1.0, "width": 0.05, "strength": 20.0, "aberration": 1.0},
}

# 熱浪：火焰外圍邊緣漸淡的橢圓，背景以向上飄動的雜訊扭曲並跟隨數字移動。
# 跑分時兩種等級共用 HEAT_HAZE_COUNT，強度隨火焰漸強成長；衝擊波發出後在衝擊波擴散期間增強到該等級的 HEAT_HAZE，維持到結算結束。
# size：橢圓半徑，x 相對整串數字的半寬、y 相對字高；lift：橢圓中心離字底的字高；
# strength：最大位移（像素）；frequency：雜訊密度（每像素）；speed：雜訊向上飄動的速度（每秒像素）。
const HEAT_HAZE_COUNT = {"size": Vector2(1.4, 2.0), "lift": 1.1, "strength": 1.5, "frequency": 0.05, "speed": 50.0}
const HEAT_HAZE = {
	Feel.Tier.HOLOGRAPHIC: {"size": Vector2(1.6, 2.4), "lift": 1.2, "strength": 2.5, "frequency": 0.05, "speed": 80.0},
	Feel.Tier.GALAXY: {"size": Vector2(2.0, 3.0), "lift": 1.4, "strength": 3.0, "frequency": 0.06, "speed": 140.0},
}
