extends RefCounted

const Catalog = preload("res://src/configs/cat_cards/cat_catalog.gd")
const Config = preload("res://src/configs/cat_cards/cat_feedback_config.gd")
const Numbers = preload("res://src/configs/gameplay/gameplay_ui_config.gd")
const Cards = preload("res://src/service/gameplay/cards.gd")

static func effect(event: Dictionary) -> String:
	if event.kind == "selection":
		return Config.SELECTION_TEXT
	if event.kind == "repeat":
		return Config.REPLAY_TEXT
	var sign_text := "+" if event.op == "add" else "x"
	return sign_text + Numbers.precise(event.amount)

static func flow(event: Dictionary) -> String:
	if event.kind == "selection":
		return Config.SELECTION_FLOW % Catalog.CARDS[event.source].name
	if event.kind == "repeat":
		return "%s / %s +%s / %s -> %s" % [Catalog.CARDS[event.source].name,
			Config.REPLAY_TEXT, Numbers.precise(event.amount), Numbers.precise(event.before), Numbers.precise(event.after)]
	var destination: String = Config.TARGET_NAMES[event.target]
	return "%s -> %s %s  /  %s -> %s" % [Catalog.CARDS[event.source].name, destination,
		effect(event), Numbers.precise(event.before), Numbers.precise(event.after)]

static func breakdown(result: Dictionary, index: int, board: Dictionary) -> String:
	var group: Dictionary = result.groups[index]
	var points := 0
	for cell in group.cells:
		points += Cards.points(board[cell])
	var lines: Array[String] = ["牌點 %s + 牌型達成 %s = 原始分數 %s" % [
		Numbers.precise(points), Numbers.precise(group.original_score - points), Numbers.precise(group.original_score)]]
	if not group.scoring:
		lines.append(Config.EXCLUSION_TEXT % Catalog.CARDS[group.excluded_by].name)
	for event in result.events:
		if event.group == index and not event.source.is_empty():
			lines.append(flow(event))
	lines.append("此組合計：%s" % Numbers.precise(group.total_score))
	return "\n".join(lines)
