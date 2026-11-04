# 字型與像素感

遊戲的數字及拉丁字母使用 BM HANNA Pro，中文使用 Cubic 11。所有 Label、Button、Tooltip、Combo、牌面點數、牌庫與金錢、關卡面板及結果面板共用專案 Theme；中央大分數透過同一個字型庫取得字型進行繪字。字型隨 Windows 與 Web 發行檔內嵌，缺字補字來源明確指定為專案內的 Cubic 11。

## 統一設定

`src/configs/fonts/font_config.gd` 提供 `NUMBER_PIXEL_ENABLED` 與 `CHINESE_PIXEL_ENABLED`，可分別開關數字及中文字型的像素感。修改後重新執行遊戲即可生效；編輯器預覽可重新載入專案。更新設定後重新匯出，發行版本才會套用新設定。

像素模式關閉字型抗鋸齒及次像素定位，固定以一倍取樣繪字，配合現有的 Nearest 材質過濾呈現硬邊像素。平滑模式開啟灰階抗鋸齒與自動取樣。開關控制的是同一套字型的繪製方式，Cubic 11 的方格字形與 BM HANNA Pro 的原始輪廓持續保留。中文小字採用 12 px、大標題採用 24 px；既有的 Combo、鏡頭與分數縮放動畫保留，動畫及視窗非整數縮放時像素格會隨顯示比例變化。

`font_library.gd` 共用數字與中文 FontFile 組成的字型鏈，套用各自的像素設定。JOKER 文字使用同一字型庫提供的獨立像素字型鏈，關閉灰階抗鋸齒，配合卡片畫布的 Nearest 取樣保留純字色。`game_theme.gd` 將此字型鏈接入全域 Theme，`project.godot` 指向 `src/configs/fonts/game_theme.tres`。字型來源及預設字級由 font config 管理，各元件的既有用途字級保留於其 config 或場景。

## 字型子集

BM HANNA Pro 本身包含部分漢字，因此遊戲使用 `src/assets/fonts/generated/PawsNumerals.ttf` 作為優先字型。此檔由原始 BM HANNA Pro 保留拉丁字母、數字、標點及數學符號而成，原始字型仍保留於 `src/assets/fonts/BMHANNAPro.ttf`；派生字型的家族名為 Paws Numerals，字形沿用原始設計。漢字與缺少的符號交由 Cubic 11 補齊，讓中文與數字混排時仍各自使用指定字型。

子集來源、輸出路徑、名稱與 Unicode 範圍位於 `src/configs/fonts/numeral_subset.json`。需更新子集時，在已安裝 `fonttools==4.60.1` 的 Python 環境執行 `python3 tools/fonts/generate_numerals.py`，再由 Godot 重新匯入。一般調整像素感只需修改 font config。

## 分數進度與匯出

Level board 使用 `目前分數 / 目標分數` 格式，斜線兩側各保留一個空格。進度字級由 `level_board_config.gd` 的 `PROGRESS_FONT_SIZE` 與 `MIN_PROGRESS_FONT_SIZE` 管理，依數字欄位寬度調整，並預留本次累加終值的寬度，讓高等級與較長分數保持完整顯示。

Windows x86_64 發行檔位於 `build/windows/paws-and-scythe.exe`，遊戲資源內嵌於 EXE。Web 發行檔位於 `build/web/index.html`，使用無執行緒模板，可透過 HTTP 伺服器試玩。各版的 ZIP 包含完整發行檔與 `licenses/` 下的字型及引擎授權文字；BM HANNA Pro 的原始製作檔與開發用工具留在專案中，發行檔使用產生的字型子集。
