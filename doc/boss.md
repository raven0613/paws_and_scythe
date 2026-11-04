# Boss 區域與技能輪替

Boss 區域入口為 `src/scenes/boss/boss.tscn`，依 `gameplay2` 放在畫面右側，由下方的 `hand`、中間的 `reaper_card` 與上方的 `boss_skill` 組成。這三組節點的位置由場景設定，可以在編輯器自由調整。技能面板的群組位置由 `boss_skill/panels` 設定，燈號群組由 `boss_skill/lights` 設定。

## 死神卡片

`src/scenes/boss/reaper_card.tscn` 是獨立的共用卡片場景，使用原尺寸 125 × 157 px 的 `reaper_bg.png`。`Card Title` 預設為 `JOKER`，逐字直排於左上角，右下角以 180° 倒轉呈現相同名稱；`Artwork` 可指定卡面圖片。

`Card Angle` 控制卡片在透明 SubViewport 內旋轉，完成後以最近鄰取樣顯示整張卡，讓牌框、卡面與文字一起維持像素邊緣。兩角的 JOKER 文字透過共用字型庫取得專用像素字型，關閉抗鋸齒及次像素定位，以純字色呈現邊緣。Boss 場景預設角度為 15°。整張卡的位置透過場景節點調整，像素旋轉透過 `Card Angle` 調整。

## 三燈與技能週期

每個技能持續三個等級。初始三燈皆暗，每完成一個等級亮起一顆燈；第三顆亮起後短暫停留，播放技能切換，完成後重置三燈亮度並開始下一個週期。等級完成次數與技能序號由 `src/service/boss/boss_skill_cycle.gd` 管理，週期長度集中在 `src/configs/boss/boss_skill_config.gd`。

技能顯示使用三張共用 `boss_skill_bg.png` 的面板循環輪替。平時左上方是亮色前牌，右下方是深色後牌，第三張隱藏於下方。切換時，前牌向上移動並淡出，深色後牌旋轉移至前牌位置並變亮，第三張從下方暗處上移為新的深色後牌。淡出的舊前牌回收為下一次預備面板。

`Skill Texts` 提供依序循環的技能文字，目前預覽只收錄參考圖的「2 COMBO以下不計分」。這個場景負責技能呈現與輪替通知，技能對遊戲計分的效果由遊戲邏輯接入。

## 呼叫與編輯

| 用途 | 入口 |
| --- | --- |
| 完成一個等級 | 呼叫 `boss_skill.complete_level()` |
| 編輯器逐關預覽 | 選取技能根節點，按「預覽：通過一個等級」 |
| 技能切換完成通知 | `skill_changed(skill_index, skill_text)` |
| 動畫完成通知 | `transition_finished` |
| 換牌文字 | 技能根節點的 `Skill Texts` |
| 前後牌顏色、燈色、動作位置與時間 | `src/configs/boss/boss_skill_config.gd` |

切換中收到的等級完成事件會依序排隊處理，確保每一關都計入燈號與技能週期。切換訊號在面板動畫完成、燈號重置後發出，供關卡系統更新對應技能資料。
