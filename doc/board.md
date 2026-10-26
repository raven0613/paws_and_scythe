# 核心放牌區

`src/nodes/gameplay.tscn` 已放入 `src/scenes/board/board.tscn`，參考畫面的位置為 `(260, 60)`、可用尺寸為 `500 × 482`。可在 gameplay 編輯器移動或調整 board 的尺寸，牌陣及待放格會在這個範圍內置中，範圍擴大時平滑縮小。格子座標可向四個方向延伸，視口邊緣只負責裁切顯示。

## 場景責任

`playing_card.tscn` 呈現卡牌原本的牌面、陰影、overlay 與 stamp，並提供手牌選取輸入。手牌選取時出現外框，再點同一張取消選取。放牌時將同一個卡牌實例移入 board，因此牌面與附加圖層會一起保留。

`src/scenes/card_placement/card_placement.tscn` 使用底色、外框與加號素材，提供 `Initial`、`Available` 兩種 State。Initial 在下方顯示「放置第一張牌」；Available 顯示加號。此場景只處理顯示、滑鼠與鍵盤按鈕輸入，點擊送出 `placement_requested(cell)`，合法座標由 board 提供。在 gameplay 中，選取手牌後才啟用待放格。

`board.tscn` 的 `content/cards` 包含實際的 playing_card，`content/placements` 包含依規則生成的 card_placement。空盤只提供初始中心格；其餘情況收集所有卡牌上下左右的空位，合併重複格子並排除已有卡牌的位置。環狀結構內的空格及孤立牌群周圍的空位套用相同規則。牌陣縮放涵蓋卡牌與待放格，讓下一張牌的落點維持可見。

## 遊戲串接

`src/scripts/gameplay/gameplay_placement.gd` 串接手牌選取、board 放牌請求及操作列的撤銷訊號。選取手牌後點待放格，卡牌移入 board，手牌收攏且背景同步縮短。每次最多放六張；撤銷會從最後一次放牌開始退回，還原卡片在手牌中的順序與原始 Y 位置，直到空盤重新顯示初始提示。

`begin_next_turn()` 供正式結算完成後呼叫，清除這次放牌的歷史並重新開放出牌，場上卡牌持續保留。`card_placed(card, cell)` 與 `placement_undone(card, cell)` 可供後續計分流程監聽。此階段使用目前手牌場景中的牌面；牌庫洗牌補牌、計分結算、關卡判定、付費交換與挖牌仍待後續功能串接。結算按鈕維持既有的請求訊號，正式結算完成後才應呼叫 `begin_next_turn()`。

## 可調設定

`src/configs/board/board_config.gd` 定義格距 `CARD_GAP`、單次出牌上限 `MAX_PLAYS_PER_TURN`、視口留白 `VIEW_PADDING`、預設縮放與縮放動畫時間。`src/configs/card_placement/card_placement_config.gd` 定義初始提示、底色、外框及 hover 顏色。手牌選取外框設定放在 `src/configs/playing_card/playing_card_config.gd`。

核心規則測試為 `tests/board/board_rules_test.gd`，涵蓋初始位置、四向相鄰、對角線排除、重複落點、中央補洞、孤島、負座標、單次出牌上限與牌陣適配。場上容量依規格在結算時判定，待放格計算只依牌位決定。
