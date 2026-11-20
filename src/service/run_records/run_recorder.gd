extends RefCounted

signal updated
signal archived(document: Dictionary)

const Config = preload("res://src/configs/run_records/record_config.gd")
const Snapshot = preload("res://src/service/run_records/record_snapshot.gd")
const Summary = preload("res://src/service/run_records/record_summary.gd")

var _game: RefCounted
var _data: Dictionary = {}
var _pending: Dictionary = {}
var _phase := "play"
var _started_ms := 0
var _undo_stack: Array = []
var _cat_instances: Dictionary = {}
var _acquisitions := 0

func _init(game: RefCounted) -> void:
	_game = game
	game.transaction_started.connect(_begin)
	game.transaction_completed.connect(_commit)

func _begin(kind: String, detail: Dictionary) -> void:
	if kind == "start":
		if not _data.is_empty():
			finish("restarted")
			archived.emit(document())
		_data = {}
		_phase = "play"
		_undo_stack.clear()
		_cat_instances.clear()
		_acquisitions = 0
		_started_ms = Time.get_ticks_msec()
	_pending = {"kind": kind, "detail": Snapshot.json_value(detail),
		"before": {} if kind == "start" else _state()}
	if kind == "undo":
		_pending.detail.undo_event = _undo_stack.pop_back()

func _commit() -> void:
	var kind: String = _pending.kind
	if kind == "start":
		var config: Dictionary = Snapshot.json_value(Config.rules_snapshot())
		_data = {"schema_version": Config.SCHEMA_VERSION,
			"run_id": "%s_%s" % [Time.get_datetime_string_from_system().replace(":", "-"), Crypto.new().generate_random_bytes(8).hex_encode()],
			"started_at": Time.get_datetime_string_from_system(true),
			"mode": _pending.detail.mode, "outcome": "in_progress",
			"engine_version": Engine.get_version_info().string,
			"game_version": ProjectSettings.get_setting("application/config/version", "unversioned"),
			"rules_hash": JSON.stringify(config, "", true).sha256_text(), "rules": config,
			"seeds": {"deck": str(_game.deck.rng.seed), "shop": str(_game.shop.rng.seed)},
			"events": []}
		for id in _game.cats.ids:
			_acquire(id)
	if kind in ["start", "advance"]:
		_phase = "play"
	elif kind == "shop_open":
		_phase = "shop"
	elif kind == "settle":
		_phase = "play" if _game.status == _game.Status.PLAYING else "reward"
	if kind == "buy":
		_acquire(_pending.detail.cat)
	elif kind == "sell":
		_pending.detail.instance = _cat_instances[_pending.detail.cat]
		_cat_instances.erase(_pending.detail.cat)
	if _game.status in [_game.Status.WON, _game.Status.LOST]:
		_phase = "result"
		_data.outcome = "won" if _game.status == _game.Status.WON else "lost"
		_data.ended_at = Time.get_datetime_string_from_system(true)
		_data.elapsed_ms = Time.get_ticks_msec() - _started_ms
	_pending.id = _data.events.size() + 1
	_pending.elapsed_ms = Time.get_ticks_msec() - _started_ms
	_pending.after = _state()
	if kind in ["start", "advance", "discard", "settle"]:
		_pending.detail.draws = Snapshot.json_value(_game.last_draw)
	if kind in ["place", "swap", "dig"]:
		_undo_stack.append(_pending.id)
	if kind in ["settle", "advance"]:
		_undo_stack.clear()
	if kind == "settle":
		_enrich_groups(_pending)
	_data.events.append(_pending)
	_data.final_state = _pending.after.duplicate(true)
	_pending = {}
	updated.emit()

func _acquire(id: String) -> void:
	_acquisitions += 1
	_cat_instances[id] = _acquisitions

func _state() -> Dictionary:
	var state := Snapshot.capture(_game, _phase)
	state.cat_instances = _cat_instances.duplicate()
	return state

func _enrich_groups(event: Dictionary) -> void:
	for group in event.detail.result.groups:
		group.cards = []
		for cell in group.cells:
			for placed in event.before.board:
				if placed.cell == cell:
					group.cards.append(placed.card)
		group.fingerprint = JSON.stringify([group.kind, group.direction, group.cells, group.cards]).sha256_text()

func finish(reason: String) -> void:
	if _data.is_empty() or _data.outcome != "in_progress":
		return
	_data.outcome = reason
	_data.ended_at = Time.get_datetime_string_from_system(true)
	_data.elapsed_ms = Time.get_ticks_msec() - _started_ms
	updated.emit()

func document() -> Dictionary:
	if _data.is_empty():
		return {}
	var result: Dictionary = _data.duplicate(true)
	result.elapsed_ms = result.get("elapsed_ms", Time.get_ticks_msec() - _started_ms)
	result.summary = Summary.build(result.events)
	return result
