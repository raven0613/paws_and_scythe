extends Control

signal continue_requested
signal restart_requested

const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
@onready var content := $outcome/center/panel/margin/content

func _ready() -> void:
	content.get_node("buttons/continue").pressed.connect(func(): continue_requested.emit())
	content.get_node("buttons/restart").pressed.connect(func(): restart_requested.emit())

func hide_outcome() -> void:
	$outcome.hide()

func show_outcome(game: RefCounted) -> void:
	if game.status == Run.Status.PLAYING:
		hide_outcome()
		return
	$outcome.show()
	var cleared: bool = game.status == Run.Status.LEVEL_CLEARED
	content.get_node("buttons/continue").visible = cleared
	content.get_node("buttons/restart").visible = not cleared
	var title := "Lv %d 過關" % game.level if cleared else "通關！" if game.status == Run.Status.WON else "挑戰結束"
	var detail := "Lv %d · %s / %d 分" % [game.level, Numbers.number(game.score), game.target()]
	if game.status == Run.Status.LOST:
		detail += "\n" + game.loss_reason
	content.get_node("title").text = title
	content.get_node("detail").text = detail
	content.get_node("buttons/continue" if cleared else "buttons/restart").grab_focus()
