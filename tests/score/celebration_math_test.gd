extends SceneTree

const Math = preload("res://src/service/score/celebration_math.gd")
const Slam = preload("res://src/service/score/slam_math.gd")
const Surge = preload("res://src/service/score/galaxy_surge.gd")
const Config = preload("res://src/configs/score/celebration_config.gd")
const Feedback = preload("res://src/configs/score/score_feedback_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
var failures := 0

func _init() -> void:
	var goal: float = Rules.LEVEL_TARGETS[0]
	var boundary := goal * Config.HIGH_SCORE_RATIO
	var galaxy := goal * Config.GALAXY_SCORE_RATIO
	var unforced := Config.Tier.NORMAL
	_check(Math.tier(boundary, goal, unforced) == Config.Tier.HOLOGRAPHIC, "Holographic threshold includes exact boundary")
	_check(Math.tier(boundary - Rules.COMBO_STEP, goal, unforced) == Config.Tier.NORMAL, "Below threshold uses normal feedback")
	_check(Math.tier(galaxy - Rules.COMBO_STEP, goal, unforced) == Config.Tier.HOLOGRAPHIC, "High scores below the galaxy threshold stay holographic")
	_check(Math.tier(galaxy, goal, unforced) == Config.Tier.GALAXY, "Galaxy threshold includes exact boundary")
	_check(Math.tier(0, goal, Config.Tier.HOLOGRAPHIC) == Config.Tier.HOLOGRAPHIC, "Forcing holographic overrides a low score")
	_check(Math.tier(0, goal, Config.Tier.GALAXY) == Config.Tier.GALAXY, "Forcing galaxy overrides a low score")
	_check(Math.tier(galaxy, goal, Config.Tier.HOLOGRAPHIC) == Config.Tier.GALAXY, "Forcing a lower tier keeps the earned tier")
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
	_check(is_equal_approx(Math.duration(Config.Tier.HOLOGRAPHIC, true), Slam.duration()), "Holographic final feedback uses the full slam timeline")
	_check(is_equal_approx(Math.duration(Config.Tier.GALAXY, true), Surge.lead(Config.Tier.GALAXY) + Slam.duration()), "Galaxy final feedback charges before the slam")
	_check(Surge.lead(Config.Tier.GALAXY) > 0.0 and is_zero_approx(Surge.lead(Config.Tier.HOLOGRAPHIC)), "Only galaxy charges before the slam")
	_check(Math.final_hold(Config.Tier.NORMAL) == Feedback.FINAL_HOLD, "Normal settlements use the short final hold")
	for tier in [Config.Tier.HOLOGRAPHIC, Config.Tier.GALAXY]:
		_check(Math.final_hold(tier) == Feedback.HIGH_FINAL_HOLD, "High-score settlements keep the long final hold")
	_check(Feedback.FINAL_HOLD < Feedback.HIGH_FINAL_HOLD, "Normal settlements wait less than high-score settlements")
	print("Celebration math: %d failures" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
