# 遊戲紀錄與 JSON 匯出

遊戲紀錄用於分析真人操作下的關卡難度、構築成形、牌型出現、貓牌發動與經濟收支。每場從開始到通關、敗北、重開或正常關閉使用一個 `run_id`，匯出內容包含原始事件、狀態快照與從事件推導的摘要。規則入口為 [遊戲規格](spec.md)。

## 使用與保存

畫面上方中央的「匯出本場 JSON」在操作、結算演出、獎勵、商店與結果畫面皆可使用。桌面版開啟另存檔案視窗，網頁版下載 JSON。按下按鈕時擷取目前已提交的紀錄；進行中的場次也能匯出。同場多次匯出保留相同 `run_id`，分析匯入時以這個識別碼選取最新版本。

每次成功操作、正式結算與商店交易後，自動保存至 `user://run_records/<run_id>.json`。保存先寫入同目錄暫存檔，再取代該場前一版檔案。重開時保存前一場並建立新檔；通關與敗北保留原結果。按鈕提示文字顯示本機資料夾，保存失敗時顯示錯誤，玩家仍可手動另存記憶體中的紀錄。桌面版的位置依 Godot 使用者資料目錄決定；網頁版的本機資料由瀏覽器管理，下載檔案可自行長期保存。

`outcome` 使用 `in_progress`、`won`、`lost`、`restarted`、`closed`。正常關閉未完成的場次記為 `closed`；程序強制結束或網頁直接關閉時，最後成功保存的檔案可能保留 `in_progress`。這類資料代表截至最後事件的未完成樣本，分析時應與敗北區分。紀錄用於分析，遊戲每次啟動仍建立新場次。

## 檔案結構

| 欄位 | 內容 |
| --- | --- |
| `schema_version`、`run_id` | JSON 格式版本與場次識別碼 |
| `mode` | 正常遊玩為 `human`；測試入口選零至五張貓牌開始，以及無視窗啟動檢查皆為 `test` |
| `started_at`、`ended_at`、`elapsed_ms` | UTC 開始／結束時間與經過毫秒；未結束的場次省略結束時間 |
| `engine_version`、`game_version` | 引擎版本與專案版本；專案尚未設定版本時為 `unversioned` |
| `rules`、`rules_hash` | 該場開始時的遊戲、貓牌、商店與獎勵設定快照，以及其 SHA-256 |
| `seeds` | 牌庫與商店的實際種子，以字串保存完整整數精度 |
| `outcome`、`final_state` | 結果，以及最後成功操作後的完整狀態與敗北原因 |
| `events` | 依序排列的原始事件，包含前後快照與事件明細 |
| `summary` | 全場、各關、牌型、貓牌、操作次數及收支摘要 |

數值保存核心計算精度，座標使用 `[x, y]`，卡牌 ID 沿用 `cards.gd`，種子與 RNG state 使用字串。`rules_hash` 識別數值設定；比較修改計算程式前後的資料時，應搭配專案版本。實際盤面、抽牌與上架結果是分析依據，種子供同版本調查使用。

## 事件與狀態

每筆事件具有單場遞增 `id`、`kind`、`elapsed_ms`、`detail`、`before` 與 `after`。第一筆 `start` 的 `before` 為空物件。快照保存關卡、目標、本關分數、金錢、階段、剩餘結算與棄牌額度、已用交換與挖牌、手牌、已出牌、盤面、可撤銷歷史、容量、抽牌堆張數、棄牌堆、RNG state、貓牌順序、成長狀態與規則修正。`phase` 區分 `play`、`reward`、`shop`、`result`。

| `kind` | `detail` 與用途 |
| --- | --- |
| `start`、`advance` | 新場次／新關卡，保存實際補抽 `draws` |
| `place` | 卡牌 ID 與放置格 |
| `swap`、`dig` | 目標格、挖出卡牌及實付分數 `cost` |
| `discard` | 棄掉的卡牌及實際補抽 `draws` |
| `undo` | 被撤銷操作與其原始 `undo_event` ID；前後快照保存退款及額度恢復 |
| `settle` | 正式計分結果 `result` 與實際補抽 `draws`；補牌前手牌保存在 `before.hand` |
| `shop_open`、`reroll` | 初始／重骰後商品保存在 `after.offers`，重骰另存本次費用 |
| `buy`、`sell` | 貓牌 ID、購買槽位與費用／出售收入；出售另存持有實例編號 |
| `reorder` | 調整後的貓牌順序，前後快照保留完整順序 |

只有成功的狀態變更產生事件。操作摘要的 `executed` 是成功執行次數，`retained` 是扣除撤銷後仍保留的次數，包含目前尚待結算的操作；當次待確認內容可由 `history` 查閱。`draws` 集中在實際發牌的事件中，每張包含卡牌 ID 與抽完後的牌庫張數。交換與挖牌的費用使用分數；商店買賣及過關獎勵使用金錢，分別核對。事件時間代表提交時點，涵蓋動畫、閱讀及閒置時間，分析操作節奏時應視為經過時間。

每次取得貓牌分配該場唯一 `cat_instances` 編號，跨關及排序保留；賣掉再買回同名貓牌取得新編號。`cats` 陣列的順序即為效果套用順序。每關摘要保存進關與最後的貓牌順序，結算快照保存當次持有的牌，買賣事件可還原關內持有變動。

## 結算與牌型

`settle.detail.result` 直接保存正式結算共用的計算結果，包含高牌、牌型、原始分數、逐組處理後分數、額外計分合計、Subtotal、Combo、總分及有序效果事件。原始效果事件保留來源、目標、前後數值、運算、倍率與 Copy Cat 的內層 `calculation`。

每組牌型另附參與卡牌 ID 和 `fingerprint`，由牌型種類、方向、格子與卡牌產生。相同一組在同關反覆結算使用相同指紋；延長、移動或換牌後視為新組。`scoring` 與 `excluded_by` 區分成立的有效牌型及獲得計分資格的牌型。

各關摘要列出每次 `earned`、結算前後累積分數及 `target`，並列出總入帳分、操作扣分、撤銷退款、最後達標比例與分數缺口。牌型摘要的口徑如下：

| 指標 | 計算方式 |
| --- | --- |
| `settlement_rate` | 出現該種有效牌型的結算數／全場正式結算數，同次多組算一次 |
| `scoring_settlement_rate` | 該種牌型取得計分資格的結算數／全場正式結算數 |
| `level_rate` | 出現該種有效牌型的關卡數／已開始關卡數，包含尚未結算的關卡 |
| `valid_groups`、`scoring_groups` | 各次結算有效組數及取得計分資格的組數，保留既有牌型再次計分 |
| `new_groups` | 同關首次看到的指紋數，跨關重新計數 |

高牌使用 `high > 0` 表示當次有高牌保底收入，參與出現率；高牌的組數欄位維持零。分母為零時比率為 `null`，表示尚無樣本。各牌型可同時出現，因此各種類出現率可合計超過 100%。

## 貓牌與經濟統計

全場與各關的貓牌摘要以 `held_settlements` 記錄持有該牌的結算數，`effective_settlements` 記錄至少有一筆實際數值效果或額外計分的結算數，`effective_rate` 為兩者相除。多組受益及 Copy Cat 內層重算在同一次結算合併為一次有效結算；`original_effect_rows` 與 `repeat_effect_rows` 分開保留效果明細筆數。被動辨識、容量及選組規則以 `rule_settlements` 記錄持有並套用規則的結算數。局部數值差異描述當下運算，評估移除某張貓牌的整體收益時仍須考慮後續倍率與構築互動。

各關的 `income.components` 保存固定、速通、利息及核心獎勵明細提供的其他收入，`income.reward` 為其合計，出售收入獨立列為 `income.sale`。`expenses.purchase`、`expenses.reroll` 分別保存購買與重骰支出，全場 `summary.money` 另列起始金錢。正常場次可核對「起始金錢＋獎勵＋出售－購買－重骰＝最後持有金錢」。

商店事件以 `before/after.level` 表示通過哪一關後的商店，例如第 3 關後的商店記為 `level: 3, phase: shop`。每次上架保存槽位、卡牌、稀有度、價格及當下 `can_buy`；前後快照保存金錢與持有貓牌，可分析看過、買得起、買下或放棄的商品。新買貓牌在下一關開始時才計入該關的起始構築。

## 實作與驗證

`run_state.gd` 在成功操作的修改前後發出同步交易訊號；`src/service/run_records/run_recorder.gd` 訂閱訊號並複製狀態。`record_snapshot.gd` 負責 JSON 型別與狀態快照，`record_summary.gd` 從事件產生摘要，`record_store.gd` 保存檔案。`src/scripts/run_records/record_export.gd` 負責自動保存與匯出介面，場景位於 `src/scenes/run_records/`，設定集中於 `src/configs/run_records/record_config.gd`。遊戲預覽沿用既有純計算流程；正式提交結算時才產生紀錄。紀錄元件可以獨立接到核心遊戲狀態，使用原有計分、獎勵與隨機結果。

`tests/run_records/run_records_test.gd` 驗證操作／撤銷、補牌前快照、正式結算、原始與 Copy Cat 重算、既有牌型重複計分、各關統計、交易、測試模式、重開與勝敗、不可變快照、檔案覆寫，以及有無訂閱紀錄時的隨機與分數一致性。測試集中於核心邏輯與檔案資料，執行方式為 `godot --headless --path . --script tests/run_records/run_records_test.gd`。
