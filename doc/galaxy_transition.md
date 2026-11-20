# 銀河轉場

最終分數達到本關完整目標 `GALAXY_SCORE_RATIO` 倍的結算使用銀河表演，或由 `FORCE_HIGH_SCORE` 設為 `Tier.GALAXY` 強制使用。跑分過程與全像彩虹表演相同，數字由白色漸變為全像彩虹；轉場併入結算完成表演的撞頂，撞頂的瞬間就是由彩虹炸開成銀河的瞬間，整段只有撞頂與落地兩次畫面震動。表演等級、填色、火焰與撞擊表演的共用規則見 [結算分數演出](settlement.md)。

## 蓄力

最後一段跑分完成後，數字先蓄力 `CHARGE_DURATION` 秒再衝上撞頂：彩虹流速在期間加速到 `CHARGE_FLOW` 倍、亮度提高 `CHARGE_BRIGHTNESS`，數字壓扁到 `CHARGE_SQUASH`。蓄力結束時流速與亮度回到原值，數字依原本的撞擊表演起跳。

## 撞頂炸開

數字撞上天花板的瞬間播放 `IMPACT_DURATION` 秒的閃白反轉幀，取代全像彩虹撞頂的白色閃光：填色整片換成高亮青白 `IMPACT_FILL`，外層白描邊反轉成深紫黑 `IMPACT_OUTLINE`，暗角同時出現。反轉幀在數字貼住天花板的頓停期間結束，填色直接換成銀河，同時由上緣兩端噴出撞頂碎片，並從數字中心發出本次結算唯一一次的銀河衝擊波，火焰外圍的熱浪隨之增強到銀河的強度，詳見 [高分衝擊波、熱浪與火焰發光](impact_effects.md)。純色的反轉幀把彩虹與銀河完全隔開，兩者不經過混色。碎片顏色取自銀河填色，數量使用 `CEILING_DEBRIS_COUNT`、`FLOOR_DEBRIS_COUNT` 的銀河設定，多於全像彩虹。

撞頂的數字震動、畫面震動、火焰噴發，以及之後的下墜、落地、彈跳與旋轉沿用原本的撞擊表演；落地的閃白照常播放。火焰在換成銀河後的 `FIRE_BLEND_DURATION` 秒內以色溫漸變由彩虹組過渡到銀河組，動態同步加快。

## 暗角

暗角為帶透明度的超深藍紫 `VIGNETTE_COLOR`，鋪滿畫面，由畫面中心往外加深，用途是讓周圍稍微變暗、把視線聚焦到分數。圖層位於盤面背景、周邊 UI、Combo 條標題、關卡分數與衝擊波熱浪的背景扭曲之上，位於飛行粒子、中央分數與火焰碎片、右側倍率之下；發動中的貓牌、亮相中的牌與高分入帳中的左上進度條位於暗角上方。

撞頂瞬間暗角以半徑 `VIGNETTE_RADIUS`、強度 `VIGNETTE_INTENSITY` 出現，隨即在 `VIGNETTE_BURST_DURATION` 內猛地彈開到 `VIGNETTE_BURST_RADIUS`，強度以 `VIGNETTE_FLICKER` 的幅度快速閃爍並在 `VIGNETTE_FLICKER_DURATION` 內衰減。半徑以畫面半高為 1、從畫面中心起算，`VIGNETTE_SOFTNESS` 為由透明到最暗的過渡寬度。`VIGNETTE_AFTERGLOW` 選擇彈開後的收尾：`Afterglow.LINGER` 在 `VIGNETTE_FADE_DURATION` 內收回 `VIGNETTE_LINGER_RADIUS` 並淡到 `VIGNETTE_LINGER_INTENSITY`，以淡淡的暗角聚焦分數到結算結束；`Afterglow.FADE` 在同樣時間內散去。

## 停留與跳過

結算完成表演結束後，最終分數停留 `HIGH_FINAL_HOLD`（`score_feedback_config.gd`）再飛往關卡面板，銀河、火焰、熱浪與暗角在停留期間持續播放。加速播放時蓄力、反轉幀、火焰漸變與暗角跟隨播放速度；跳過時清除反轉幀、銀河、火焰漸變與暗角，回到全像彩虹的初始狀態。

## 元件與設定

| 檔案 | 責任 |
| ---- | ---- |
| `src/configs/score/galaxy_transition_config.gd` | 蓄力、反轉幀、火焰漸變時間與暗角的全部參數。 |
| `src/configs/score/celebration_config.gd` | 表演等級門檻、強制等級、各等級碎片數量、兩組火焰與速度倍率。 |
| `src/service/score/galaxy_surge.gd` | 銀河等級的蓄力長度與蓄力姿態，以及撞頂後的反轉幀、換成銀河的時間點與火焰漸變比例。 |
| `src/service/score/vignette_motion.gd` | 暗角的出現、彈開、閃爍與收尾。 |
| `src/service/score/celebration_math.gd` | 結算完成表演長度，銀河等級包含蓄力。 |
| `src/service/score/slam_math.gd` | 撞擊時間軸；銀河撞頂的閃白交給反轉幀。 |
| `src/scripts/score/score_counter.gd` | 播放蓄力、偵測撞頂、切換彩虹與銀河填色、驅動反轉幀描邊、撞頂碎片、火焰漸變與暗角。 |
| `src/scripts/score/celebration/vignette.gd`、`vignette.gdshader` | 鋪滿畫面的暗角圖層與繪製。 |
| `src/scripts/score/celebration/flash.gdshaderinc` | 撞擊閃白與反轉幀填色。 |

核心測試位於 `tests/score/galaxy_transition_test.gd`，驗證蓄力期間彩虹加速變亮且數字壓扁，撞頂以反轉幀開場並在天花板頓停期間結束，反轉幀後直接換成銀河、火焰逐漸漸變並完成於銀河組，以及暗角在撞頂時以最緊的狀態出現、彈開、閃爍，並依收尾設定留下淡暗角或散去。`tests/score/celebration_math_test.gd` 驗證表演等級的門檻與強制等級，以及只有銀河在撞擊前蓄力；`tests/score/slam_math_test.gd` 驗證各等級碎片數量與銀河撞頂閃白交給反轉幀；`tests/score/flame_math_test.gd` 驗證兩組火焰漸變。
