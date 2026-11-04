# 核心放牌區

`src/nodes/gameplay.tscn` 使用 `src/scenes/board/board.tscn`，牌陣節點隨主畫面鋪滿完整背景。格子座標可向四個方向延伸，牌陣顯示於四周黑邊及固定介面下層，露出的背景呈現其完整形狀。自動適配使用黑邊與固定介面內的安全範圍計算中心及縮放，繪製範圍持續覆蓋整個背景。

## 場景責任

`playing_card.tscn` 呈現卡牌牌面、陰影、overlay、stamp 與最上層的牌型標示，並提供選取輸入。遊戲以唯一卡牌 ID 設定點數、花色及對應顏色；同一實體牌在手牌與牌陣間移動時沿用同一個場景實例，保留附加圖層。手牌選取使用向上位移，點擊同一張可取消，支援同時選取多張。

`src/scenes/card_placement/card_placement.tscn` 使用底色、外框與加號素材，提供 `Initial`、`Available` 兩種狀態。Initial 在下方顯示「放置第一張牌」；Available 顯示加號。點擊待放格送出 `placement_requested(cell)`，合法座標由 board 提供。空盤直接顯示中心起始格，選取一張手牌後啟用點擊。已有卡牌時，恰好選取一張手牌且仍有出牌額度才顯示待放格；出牌後、取消選取、選取多張及進入場上操作模式時收起。顯示與收起均使用透明度與縮放補間。收起時立即釋放滑鼠輸入，讓空白處可拖曳鏡頭。

`board.tscn` 的 `content/cards` 包含實際的 playing_card，`content/placements` 包含依規則生成的 card_placement。空盤提供中心初始格；其餘情況收集所有實體卡牌上下左右的空位，合併重複格子並排除已有卡牌的位置。環狀結構內的空格及孤立牌群周圍的空位套用相同規則。合法空位在更新時沿用既有實例，移除的空位完成退場補間後釋放。

## 遊戲串接

`src/scripts/gameplay/gameplay.gd` 將 `src/service/gameplay/run_state.gd` 的手牌、牌陣與操作狀態更新至場景，連接選牌、待放格、操作列、牌型清單及關卡結果。所有操作先通過核心規則，再由畫面呈現結果。放牌、交換、挖牌共用後進先出的操作歷史，撤銷時同時還原牌位、手牌位置與額度，並退回已支付費用；棄牌與補抽立即確認。

場上卡牌在挖牌模式可點擊挖除，在交換模式可依序選取兩張交換。主要牌型依類型使用微暗描邊，滑過 Combo 清單時，該組卡牌以整組外接矩形中心平滑放大，移開後平滑恢復；卡牌格位和計分資料保持原值，交叉牌依當前組合的中心縮放。結算沿用預覽所採用的分組，保留場上卡牌，並依關卡結果補牌或進入結果畫面。完整規則與責任分工見 [核心遊戲流程](core_gameplay.md)。

## 鏡頭與設定

`src/scripts/board/board_camera.gd` 負責鏡頭適配、平移與縮放。自動追蹤預設開啟，以所有場上實體牌及合法待放格的外接矩形為準，包含當下隱藏的待放格；場上結構改變時平滑適配。完整牌陣置中於黑邊及固定介面內的安全區，四周保留間隙。玩家可在空白背景以滑鼠左鍵或中鍵拖曳，使用滾輪及 Mac 觸控板捲動以游標為中心縮放，手機則以雙指中點捏合縮放。Zoom In／Out 按鈕以安全區中心平滑縮放，Reset 與 Auto 共用完整適配。手動視角維持至下一次牌陣結構變動；關閉追蹤後由玩家控制，重新開啟時立即平滑適配。場景分工、觸控判定與安全區算法詳見 [鏡頭控制、牌庫與金錢](gameplay_controls.md)。

格距、鏡頭邊距、縮放上下限與動畫時間集中於 `src/configs/board/board_config.gd`，出牌上限共用 `src/configs/gameplay/game_rules.gd`。待放格提示、顏色及補間集中於 `src/configs/card_placement/card_placement_config.gd`，手牌向上位移量由 `src/configs/hand_area/hand_area_config.gd` 的 `SELECTED_OFFSET` 控制，牌型標示的線寬與透明度由 `src/configs/playing_card/playing_card_config.gd` 控制。

`tests/board/board_rules_test.gd` 驗證初始位置、四向相鄰、對角線排除、重複落點、中央補洞、孤島、負座標；`tests/board/camera_math_test.gd` 驗證含待放格的安全適配、手勢縮放與觸控辨識。單次出牌上限由核心流程測試驗證。場上容量由核心流程在結算時判定。
