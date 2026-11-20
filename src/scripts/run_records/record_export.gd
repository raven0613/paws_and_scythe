extends CanvasLayer

const Recorder = preload("res://src/service/run_records/run_recorder.gd")
const Store = preload("res://src/service/run_records/record_store.gd")
const Config = preload("res://src/configs/run_records/record_config.gd")
const Style = preload("res://src/scripts/ui/box_style.gd")

var recorder: RefCounted
var _export: Dictionary = {}
@onready var button: Button = $controls/export
@onready var notice: AcceptDialog = $notice
@onready var dialog: FileDialog = $file_dialog

func _ready() -> void:
	button.text = Config.EXPORT_LABEL
	Style.apply_button(button, Config.FONT_SIZE)
	button.pressed.connect(_choose_export)
	dialog.file_selected.connect(_save_export)
	dialog.canceled.connect(func(): _export = {})

func setup(game: RefCounted) -> void:
	recorder = Recorder.new(game)
	recorder.updated.connect(_checkpoint)

func _checkpoint() -> void:
	var error := Store.save(recorder.document())
	button.tooltip_text = "本機紀錄：" + ProjectSettings.globalize_path(Config.DIRECTORY)
	if error != OK:
		button.tooltip_text = "自動保存失敗：%s；可使用匯出按鈕另存。" % error_string(error)

func _choose_export() -> void:
	_export = recorder.document()
	var filename: String = _export.run_id + ".json"
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(JSON.stringify(_export, "\t", false, true).to_utf8_buffer(), filename, "application/json")
		_export = {}
	else:
		dialog.current_file = filename
		dialog.popup_centered_ratio()

func _save_export(path: String) -> void:
	if path.get_extension().to_lower() != "json":
		path += ".json"
	var error := Store.write_json(path, _export)
	if error == OK:
		notice.dialog_text = "已匯出遊戲紀錄：\n" + path
	else:
		notice.dialog_text = "匯出失敗：%s\n請選擇可寫入的資料夾後重試。" % error_string(error)
	notice.popup_centered()
	_export = {}

func _exit_tree() -> void:
	if recorder != null:
		recorder.updated.disconnect(_checkpoint)
		recorder.finish("closed")
		Store.save(recorder.document())
