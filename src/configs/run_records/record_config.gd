extends RefCounted

const SCHEMA_VERSION = 1
const DIRECTORY = "user://run_records"
const EXPORT_LABEL = "匯出本場 JSON"
const FONT_SIZE = 18
const RULE_SCRIPTS = {
	"game": preload("res://src/configs/gameplay/game_rules.gd"),
	"cats": preload("res://src/configs/cat_cards/cat_catalog.gd"),
	"shop": preload("res://src/configs/shop/shop_config.gd"),
	"reward": preload("res://src/configs/level_reward/reward_config.gd"),
}

static func rules_snapshot() -> Dictionary:
	var result := {}
	for key in RULE_SCRIPTS:
		result[key] = RULE_SCRIPTS[key].get_script_constant_map()
	return result
