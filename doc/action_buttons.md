# 操作按鈕回饋

關卡面板右側的五顆操作按鈕共用 `action_button.tscn`，排列、圖示、文字與剩餘次數見 [遊戲規格](spec.md)。本文件說明按鈕的 Hover 動態與底色水面的晃動。

## Hover 動態

滑鼠進入可用的按鈕時，按鈕以 Back Out 放大，同時播放衰減的位移與旋轉抖動，停留期間維持放大並位於其他按鈕上層；離開時平滑恢復尺寸、位置與角度。左右按鈕依放大後的寬度讓出間隙，全體推移同時開始，每側設定範圍內的按鈕依距離接續疊加擾動位移與旋轉，每遠一顆強度乘上衰減倍率。滑鼠直接移到相鄰按鈕時，前一顆恢復、新的一顆放大，推開的空間隨之轉移；離開所有按鈕後間距平滑收回。

動態與 combo 條 Hover 使用相同的共用元件與相同的預設數值，兩者各自擁有一組設定，可分別調整。按鈕根節點固定在排列中負責輸入，`spacing` 子節點承接推開，`spacing/visual` 承接放大與抖動，視覺變形期間的 Hover 判定保持穩定。停用的按鈕維持原狀，同樣會被鄰近按鈕推開。按下時套用 `PRESSED_TINT`，停用時套用 `DISABLED_TINT`。

## 水面晃動

底色平時以兩層緩慢波浪模擬平靜的水面。外框被當成裝水的箱子：按鈕放大抖動時甩動一次，離開縮回時朝反方向再甩一次，被推開或回位的鄰居依推移方向各甩一次，強度隨距離遞減，並在各自的擾動開始時發生。

每次甩動讓水因慣性往反側堆高，水面以阻尼彈簧左右傾斜擺盪，同時翻起較短、較快的碎浪；停在按鈕上時水面逐漸平靜，多次甩動的能量相互疊加，碎浪能量有上限。水面完全平靜後停止更新，平靜時的外觀與原本的波浪相同。

## 元件與設定

| 檔案 | 責任 |
| --- | --- |
| `src/scripts/action_buttons/action_buttons_hover.gd` | 偵測 Hover 的可用按鈕，播放放大抖動、推開鄰居，並在各時機觸發水面甩動。 |
| `src/scripts/action_buttons/action_button.gd` | 按鈕外觀與次數，提供 `hover_visual()`、`spacing_visual()`，以 `slosh(impulse)` 接收甩動並更新水面。 |
| `src/scripts/action_buttons/calm_waves.gdshader` | 平靜波浪疊加水面斜率與碎浪。 |
| `src/service/action_buttons/water_slosh.gd` | 甩動、阻尼擺盪、碎浪衰減與平靜判定的純計算。 |
| `src/scripts/motion/hover_pop.gd`、`src/scripts/motion/displacement.gd`、`src/service/motion/displacement_math.gd` | 與 combo 條共用的 Hover 放大抖動、排列推移與擾動。 |

`src/configs/action_buttons/action_button_motion_config.gd` 集中所有動態數值：`HOVER_*` 控制放大倍率、放大時間、抖動位移與旋轉、抖動次數、衰減、恢復時間、圖層、左右間隙及每側擾動範圍；`PUSH_DURATION` 與 `DISTURB_*` 控制推移時間、擾動位移、旋轉、間隔、時長、次數、衰減與逐顆強度倍率；`SLOSH_*` 控制水面傾斜幅度、擺盪頻率、阻尼比、碎浪振幅、能量上限、平靜時間、碎浪波長與速度，以及進入、離開與鄰居的甩動強度。平靜水面的顏色、速度、振幅、波長與水位設定於 `action_button.tscn` 的 `waves` 材質；色調、間距與次數外觀集中於 `action_button_config.gd`。

`tests/action_buttons/water_slosh_test.gd` 驗證甩動方向、擺盪峰值、回擺越過水平、逐漸平靜、碎浪衰減與上限，以及不同幀率的穩定結果；共用推移與擾動的計算由 `tests/motion/displacement_math_test.gd` 驗證。
