extends RefCounted

const Config = preload("res://src/configs/score/score_feedback_config.gd")

var current := 0.0
var target := 0.0
var active := false
var _from := 0.0

func reset(amount: float) -> void:
	current = amount
	_from = amount
	target = amount
	active = false

func begin(amount: float) -> void:
	if active:
		finish()
	_from = current
	target = amount
	active = current != target

func advance(progress: float) -> void:
	if not active:
		return
	if progress >= 1.0:
		finish()
	else:
		current = value(_from, target, progress)

func finish() -> void:
	current = target
	active = false

static func value(from: float, target: float, progress: float) -> float:
	var distance := absf(target - from)
	var tail := minf(Config.COUNT_TAIL, distance * (1.0 - Config.COUNT_MAIN_RATIO))
	var direction := signf(target - from)
	if progress < Config.COUNT_MAIN_RATIO:
		return from + direction * (distance - tail) * progress / Config.COUNT_MAIN_RATIO
	return target - direction * tail * (1 - progress) / (1 - Config.COUNT_MAIN_RATIO)

static func scale_at(progress: float) -> Vector2:
	var pop := 0.0
	if progress >= Config.NUMBER_POP_START and progress < Config.NUMBER_POP_PEAK:
		pop = sin((progress - Config.NUMBER_POP_START) / (Config.NUMBER_POP_PEAK - Config.NUMBER_POP_START) * PI / 2)
	elif progress >= Config.NUMBER_POP_PEAK:
		pop = sin((1 - progress) / (1 - Config.NUMBER_POP_PEAK) * PI / 2)
	return Vector2.ONE * lerpf(1.0, Config.NUMBER_POP_SCALE, pop)
