extends SceneTree

const Config = preload("res://src/configs/boss/boss_skill_config.gd")
const Cycle = preload("res://src/service/boss/boss_skill_cycle.gd")


func _init() -> void:
	var cycle = Cycle.new()
	assert(cycle.completed_levels == 0 and cycle.skill_index == 0)
	for expected_skill in range(Config.LEVELS_PER_SKILL):
		for passed in range(1, Config.LEVELS_PER_SKILL):
			assert(not cycle.complete_level(), "A skill must last the configured number of levels.")
			assert(cycle.completed_levels == passed)
			assert(cycle.skill_index == expected_skill)
		assert(cycle.complete_level(), "The last light must trigger a skill change.")
		assert(cycle.completed_levels == 0, "The next cycle must start with all lights reset.")
		assert(cycle.skill_index == expected_skill + 1, "Each completed cycle advances one skill.")
	print("Boss skill cycle passed: lights advance once per level and reset every skill cycle.")
	quit()
