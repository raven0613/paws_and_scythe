@tool
extends RefCounted

const Config = preload("res://src/configs/boss/boss_skill_config.gd")

var completed_levels: int = 0
var skill_index: int = 0


func complete_level() -> bool:
	completed_levels += 1
	if completed_levels < Config.LEVELS_PER_SKILL:
		return false
	completed_levels = 0
	skill_index += 1
	return true
