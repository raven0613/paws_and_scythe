extends RefCounted

const Config = preload("res://src/configs/level_reward/reward_config.gd")

# 過關獎勵明細依基礎、貓牌、速通、任務單、利息排列，total 為全部金額。
# 每項的 kind 標示來源、amount 為金額、detail 為說明用數值：速通為剩餘結算次數，利息為計息的持有金錢，
# 貓牌與任務單為來源 ID。貓牌與任務單的獎勵由各自系統以 {"id", "amount"} 提供。
static func compute(held_money: int, turns_left: int, cat_bonuses: Array = [], quest_bonuses: Array = []) -> Dictionary:
	var entries: Array[Dictionary] = [_entry("base", Config.BASE, 0)]
	for bonus in cat_bonuses:
		entries.append(_entry("cat", bonus.amount, bonus.id))
	entries.append(_entry("speed", turns_left * Config.SPEED_PER_SETTLEMENT, turns_left))
	for bonus in quest_bonuses:
		entries.append(_entry("quest", bonus.amount, bonus.id))
	entries.append(_entry("interest", interest(held_money), held_money))
	var total := 0
	for entry in entries:
		total += entry.amount
	return {"entries": entries, "total": total}

# 每持有一個完整 INTEREST_STEP 給 1 元，最多 INTEREST_CAP 元。
static func interest(held_money: int) -> int:
	return mini(held_money / Config.INTEREST_STEP, Config.INTEREST_CAP)

static func _entry(kind: String, amount: int, detail: Variant) -> Dictionary:
	return {"kind": kind, "amount": amount, "detail": detail}
