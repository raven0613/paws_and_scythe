extends SceneTree

const Config = preload("res://src/configs/gameplay/curve_probe_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const RewardConfig = preload("res://src/configs/level_reward/reward_config.gd")
const Balance = preload("res://src/configs/cat_cards/cat_balance_config.gd")
const LevelReward = preload("res://src/service/level_reward/level_reward.gd")
const Market = preload("res://src/service/shop/cat_market.gd")
const Player = preload("res://tests/support/probe_player.gd")

# 逐關模擬：每位玩家以目前持有的貓牌量測六次結算，建議目標取第 CLEAR_TURNS 次的中位累積分數；
# 玩家以建議目標下實際達標的結算次數領取過關獎勵，再依路線順序購買下一張貓牌。
# 簡化假設：商店總能提供路線上的下一張貓牌，玩家不重骰也不賣牌。
func _init() -> void:
	var players := _players()
	var targets: Array = []
	for level in range(1, Rules.LEVEL_TARGETS.size() + 1):
		var runs: Array = []
		for index in players.size():
			runs.append(Player.measure(Config.SEED + index * Rules.LEVEL_TARGETS.size() + level, players[index].owned))
		var target := _target(runs, Config.CLEAR_TURNS[level - 1], 0 if targets.is_empty() else targets[-1])
		targets.append(target)
		var report := {"level": level, "target": target, "turn": Config.CLEAR_TURNS[level - 1]}
		report.cats = Player.median(players.map(func(player): return player.owned.size()))
		report.money = Player.median(players.map(func(player): return player.money))
		var cleared: Array = runs.map(func(totals): return _clear_turn(totals, target))
		report.fail_rate = cleared.filter(func(turn): return turn > Rules.SETTLEMENTS).size() / float(players.size())
		report.median_clear = Player.median(cleared)
		report.turn_medians = range(Rules.SETTLEMENTS).map(func(turn): return roundi(Player.median(runs.map(func(totals): return totals[turn]))))
		print(JSON.stringify(report))
		for index in players.size():
			_finish_level(players[index], cleared[index])
	print("LEVEL_TARGETS = %s" % str(targets))
	quit()

func _players() -> Array:
	var players: Array = []
	for route in Balance.BUILDS:
		for strategy in Config.STRATEGIES:
			for sample in Config.SAMPLES:
				players.append({"route": Balance.BUILDS[route], "strategy": strategy, "owned": [], "money": Rules.STARTING_MONEY})
	return players

func _target(runs: Array, turn: float, previous: int) -> int:
	var lower := floori(turn)
	var weight := turn - lower
	var values: Array = runs.map(func(totals): return lerpf(totals[lower - 1], totals[mini(lower, totals.size() - 1)], weight))
	var step := _step(Player.median(values))
	return maxi(roundi(Player.median(values) / step) * step, previous + _step(previous))

func _step(value: float) -> int:
	if value < Config.SMALL_LIMIT:
		return Config.SMALL_STEP
	return Config.MEDIUM_STEP if value < Config.MEDIUM_LIMIT else Config.LARGE_STEP

# 回傳累積分數首次達標的結算次數；六次都未達標時回傳 SETTLEMENTS + 1。
func _clear_turn(totals: Array, target: int) -> int:
	for turn in totals.size():
		if totals[turn] >= target:
			return turn + 1
	return Rules.SETTLEMENTS + 1

func _finish_level(player: Dictionary, clear_turn: int) -> void:
	var turns_left := maxi(Rules.SETTLEMENTS - clear_turn, 0)
	player.money += LevelReward.compute(player.money, turns_left).total
	var reserve: int = RewardConfig.INTEREST_STEP * RewardConfig.INTEREST_CAP if player.strategy == "save" else 0
	while player.owned.size() < player.route.size():
		var next: String = player.route[player.owned.size()]
		if player.money - Market.price(next) < reserve:
			break
		player.money -= Market.price(next)
		player.owned.append(next)
