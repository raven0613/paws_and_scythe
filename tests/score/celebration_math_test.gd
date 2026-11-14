extends SceneTree

const Math = preload("res://src/service/score/celebration_math.gd")
const Slam = preload("res://src/service/score/slam_math.gd")
const Config = preload("res://src/configs/score/celebration_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
var failures := 0

func _init() -> void:
	var goal: float = Rules.LEVEL_TARGETS[0]
	var boundary := goal * Config.HIGH_SCORE_RATIO
	_check(Math.is_high(boundary, goal, false), "High-score threshold includes exact boundary")
	_check(not Math.is_high(boundary - Rules.COMBO_STEP, goal, false), "Below threshold uses normal feedback")
	_check(Math.is_high(0, goal, true), "Force switch overrides score threshold")
	_check(Math.energy(boundary * Config.ENERGY_START, boundary) == 0, "High-score effects start from white")
	_check(Math.energy(boundary * Config.ENERGY_FULL, boundary) == 1, "High-score effects reach full intensity at configured progress")
	_check(Math.energy(0, 0) == 0, "Zero result keeps white text")
	var middle := (Config.ENERGY_START + Config.ENERGY_FULL) / 2
	_check(is_equal_approx(Math.energy(boundary * middle, boundary), 0.5), "Both fill modes share smooth intermediate intensity")
	_check(Math.energy(boundary * Config.ENERGY_START / 2, boundary) == 0, "Before the transition all effects remain at rest")
	_check(Math.energy(boundary * 2, boundary) == 1, "Intensity stays bounded when an intermediate subtotal exceeds the final result")
	var events := [
		{"kind": "group_award", "before": 0.0, "after": goal},
		{"kind": "effect", "target": "multiplier", "before": 1.0, "after": 2.0},
		{"kind": "combo_apply", "before": goal, "after": goal},
	]
	_check(Math.last_central_event(events) == 0, "Unchanged central events and multiplier-only events preserve last actual count")
	events.append({"kind": "effect", "target": "total", "before": goal, "after": boundary})
	_check(Math.last_central_event(events) == events.size() - 1, "Total cat effects receive final feedback")
	_check(Math.last_central_event([]) == -1, "Empty sequences still allow standalone final feedback")
	for high in [false, true]:
		for final in [false, true]:
			if high and final:
				continue
			var pose := Math.impact(1, high, final)
			_check(pose.position.is_zero_approx() and pose.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(pose.rotation), "Step and final feedback restore exact rest pose")
	_check(is_equal_approx(Math.duration(true, true), Slam.duration()), "High-score final feedback uses the full slam timeline")
	print("Celebration math: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
