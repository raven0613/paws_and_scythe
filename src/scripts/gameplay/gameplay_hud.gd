extends Control

signal restart_requested

const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
@onready var content := $outcome/center/panel/margin/content

func _ready() -> void:
	content.get_node("buttons/restart").pressed.connect(func(): restart_requested.emit())

func hide_outcome() -> void:
	$outcome.hide()

# 敗北與整場通關顯示結果與重新開始；過關由過關獎勵畫面接手。
func show_outcome(game: RefCounted) -> void:
	if game.status != Run.Status.LOST and game.status != Run.Status.WON:
		hide_outcome()
		return
	$outcome.show()
	var detail := "Lv %d · %s / %d 分" % [game.level, Numbers.number(game.score), game.target()]
	if game.status == Run.Status.LOST:
		detail += "\n" + game.loss_reason
	content.get_node("title").text = "通關！" if game.status == Run.Status.WON else "挑戰結束"
	content.get_node("detail").text = detail
	content.get_node("buttons/restart").grab_focus()
