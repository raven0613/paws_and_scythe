extends SceneTree

const Probe = preload("res://src/configs/gameplay/balance_probe_config.gd")
const Balance = preload("res://src/configs/cat_cards/cat_balance_config.gd")
const Player = preload("res://tests/support/probe_player.gd")

# 各構築依持有張數量測六次結算的完整產出，列出中位總分與指定結算次數的中位累積分數。
func _init() -> void:
	for count in Balance.PROBE_COUNTS:
		for build_name in Balance.BUILDS:
			if count == 0 and build_name != Balance.BUILDS.keys()[0]:
				continue
			var runs: Array = []
			for sample in Balance.PROBE_SAMPLES:
				runs.append(Player.measure(Probe.SEED + sample, Balance.BUILDS[build_name].slice(0, count)))
			var finals: Array = runs.map(func(totals): return totals[-1])
			finals.sort()
			var report := {"cards": count, "build": build_name, "min": finals[0], "median": Player.median(finals), "max": finals[-1]}
			for turn in Balance.REPORT_TURNS:
				report["turn_%d" % turn] = Player.median(runs.map(func(totals): return totals[turn - 1]))
			print(JSON.stringify(report))
	quit()
