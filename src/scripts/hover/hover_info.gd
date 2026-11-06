extends CanvasLayer

const Config = preload("res://src/configs/hover/hover_config.gd")
const PanelScene = preload("res://src/scenes/hover/hover_panel.tscn")
var _panel: Control
var _source: Control
var _content: Callable

func _ready() -> void:
	layer = Config.LAYER
	_panel = PanelScene.instantiate()
	add_child(_panel)
	set_process(false)

# 內容由來源即時提供，滑入當幀顯示；滑鼠在來源內移動時維持同一面板。
func bind_source(source: Control, content: Callable) -> void:
	source.mouse_entered.connect(_show_for.bind(source, content))
	source.mouse_exited.connect(_hide_for.bind(source))
	source.tree_exiting.connect(_hide_for.bind(source))

func _show_for(source: Control, content: Callable) -> void:
	_source = source
	_content = content
	set_process(true)
	refresh()

func _hide_for(source: Control) -> void:
	if source == _source:
		_source = null
		_content = Callable()
		_panel.hide()
		set_process(false)

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if _source == null:
		return
	if not _source.is_visible_in_tree() or _source.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		_hide_for(_source)
		return
	var content: Array = _content.call()
	if content[0].is_empty() and content[1].is_empty():
		_panel.hide()
		return
	var rect := _source.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, _source.size)
	_panel.present(content[0], content[1], rect)
