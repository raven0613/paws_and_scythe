# 共用即時 Hover

資訊窗於滑鼠進入來源的當幀顯示，在來源內移動時持續顯示，移出、隱藏或移除來源時收起。全遊戲共用一個資訊窗，切換來源時直接更新內容。來源的內容與位置在顯示期間同步更新，支援貓牌排序、Combo 變動、操作成本及鏡頭縮放。

`HoverInfo` 是專案註冊的 Autoload，使用獨立 CanvasLayer 呈現資訊窗。元件在執行期的 `_ready()` 呼叫 `HoverInfo.bind_source(self, content_provider)`，提供回傳 `[標題, 說明]` 的 Callable。標題或說明可為空字串；兩者皆空時收起面板。來源持有自己的內容，Hover 系統處理進出、生命週期與呈現。需要在資料更新當下同步畫面時，可呼叫 `HoverInfo.refresh()`。

面板固定於來源右側，空間不足時移至左側並限制在視窗內。定位以來源包含 Canvas 與鏡頭的轉換計算，面板文字維持介面尺寸。面板與內部文字均忽略滑鼠事件，玩家可持續操作來源。文字先依固定寬度換行，再於同幀量測高度。

目前貓牌顯示名稱、稀有度與既有說明；Combo 顯示牌型、張數、分數拆解及貓牌明細；遊戲牌顯示卡牌與目前操作提示；操作按鈕、放牌格和鏡頭按鈕顯示對應用途。新增資訊型 Hover 由同一入口接入。

| 檔案 | 責任 |
| --- | --- |
| `src/scripts/hover/hover_info.gd` | 綁定來源、管理進出與更新單一資訊窗。 |
| `src/scripts/hover/hover_panel.gd` | 文字排版、來源定位與視窗邊界調整。 |
| `src/scenes/hover/hover_panel.tscn` | 共用面板與標題、說明節點。 |
| `src/configs/hover/hover_config.gd` | 寬度、間距、字級、配色與顯示層級。 |
