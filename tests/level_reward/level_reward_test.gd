extends SceneTree

const Config = preload("res://src/configs/level_reward/reward_config.gd")
const Rules = preload("res://src/configs/gameplay/game_rules.gd")
const LevelReward = preload("res://src/service/level_reward/level_reward.gd")
const Run = preload("res://src/service/gameplay/run_state.gd")
var failures := 0

func _init() -> void:
	_test_entries()
	_test_interest()
	_test_bonus_sources()
	_test_run_clear()
	print("Level reward tests: %d failures" % failures)
	quit(1 if failures else 0)

func _test_entries() -> void:
	var turns := Rules.SETTLEMENTS - 1
	var reward := LevelReward.compute(0, turns)
	_check(_kinds(reward) == ["base", "speed", "interest"], "Default reward lists base, speed and interest")
	_check(reward.entries[0].amount == Config.BASE, "Base reward uses config")
	_check(reward.entries[1].amount == turns * Config.SPEED_PER_SETTLEMENT, "Speed reward pays each remaining settlement")
	_check(reward.entries[1].detail == turns, "Speed entry records remaining settlements")
	_check(LevelReward.compute(0, 0).entries[1].amount == 0, "Clearing on the last settlement earns no speed reward")
	_check(reward.total == Config.BASE + turns * Config.SPEED_PER_SETTLEMENT, "Total sums every entry")

func _test_interest() -> void:
	_check(LevelReward.interest(0) == 0, "No money earns no interest")
	_check(LevelReward.interest(Config.INTEREST_STEP - 1) == 0, "Partial steps are floored")
	_check(LevelReward.interest(Config.INTEREST_STEP) == 1, "Each full step earns one")
	_check(LevelReward.interest(Config.INTEREST_STEP * 2 + 1) == 2, "Interest grows by whole steps")
	var cap_money := Config.INTEREST_STEP * Config.INTEREST_CAP
	_check(LevelReward.interest(cap_money) == Config.INTEREST_CAP, "Cap is reached at step × cap")
	_check(LevelReward.interest(cap_money * 3) == Config.INTEREST_CAP, "Interest stops at the cap")
	var reward := LevelReward.compute(cap_money, 0)
	_check(reward.entries[-1].detail == cap_money, "Interest entry records held money")
	_check(reward.total == Config.BASE + Config.INTEREST_CAP, "Interest joins the total")

func _test_bonus_sources() -> void:
	var cats := [{"id": "cat_a", "amount": 2}]
	var quests := [{"id": "quest_a", "amount": 5}]
	var reward := LevelReward.compute(0, 1, cats, quests)
	_check(_kinds(reward) == ["base", "cat", "speed", "quest", "interest"], "Cat bonuses follow base and quests follow speed")
	_check(reward.entries[1].detail == "cat_a" and reward.entries[3].detail == "quest_a", "Bonus entries keep their source id")
	_check(reward.total == Config.BASE + 2 + Config.SPEED_PER_SETTLEMENT + 5, "Bonus sources join the total")

func _test_run_clear() -> void:
	var game = Run.new()
	game.start(Rules.TEST_SEED)
	var held: int = Config.INTEREST_STEP * 2
	game.money = held
	_clear_level(game)
	var expected := LevelReward.compute(held, game.turns_left)
	_check(game.status == Run.Status.LEVEL_CLEARED, "Reaching the target clears the level")
	_check(game.reward == expected, "Clearing records the level reward from pre-reward money")
	_check(game.money == held + expected.total, "Clearing credits the reward immediately")
	game.advance()
	_check(game.reward.is_empty(), "A new level starts without a pending reward")
	game.level = Rules.LEVEL_TARGETS.size()
	var final_money: int = game.money
	_clear_level(game)
	_check(game.status == Run.Status.WON and game.reward.is_empty(), "The final level ends the run without a reward")
	_check(game.money == final_money, "Winning the run leaves money unchanged")

func _clear_level(game: RefCounted) -> void:
	game.score = game.target()
	game.place(game.hand[0], Vector2i.ZERO)
	game.settle()

func _kinds(reward: Dictionary) -> Array:
	return reward.entries.map(func(entry): return entry.kind)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
