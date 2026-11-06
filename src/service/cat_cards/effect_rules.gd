extends RefCounted

static func eligible(effect: Dictionary, context: Dictionary, index: int) -> bool:
	var count: int = context.scoring.size()
	match effect.condition:
		"always": return true
		"has_groups": return count > 0
		"untouched": return context.get("swaps", 0) == 0 and context.get("digs", 0) == 0
		"single_valid": return context.groups.size() == 1
		"single_scored": return count == 1
		"hole": return context.geometry.hole
		"islands": return context.geometry.islands > effect.threshold and context.geometry.all_islands_scoring
		"small": return count > 0 and context.scoring_longest <= effect.limit
		"unique": return count >= effect.minimum and context.kinds.size() == count
		"highest": return index == context.highest
		"longest": return context.groups[index].cells.size() == context.longest and context.longest > effect.threshold
		"kind": return context.groups[index].kind == effect.kind
		_: return context.facts[index][effect.condition]

static func amount(effect: Dictionary, context: Dictionary, index: int) -> float:
	var units := 1.0
	match effect.measure:
		"discards_used", "discards_left", "operations": units = context.get(effect.measure, 0)
		"strays": units = context.geometry.strays
		"consecutive": units = context.facts[index].consecutive
		"single_length": units = context.groups[0].cells.size()
		"extended_count":
			units = 0
			for kind in ["straight", "flush", "straight_flush"]:
				units += context.kinds.get(kind, 0)
		"kind_count": units = context.kinds.get(effect.kind, 0)
		"kinds": units = context.kinds.size()
		"hand": units = context.get("hand_count", 0)
		"settlements": units = context.get("settlements", 0) + 1
		"excess_length": units = context.groups[index].cells.size() - effect.threshold
	var result: float = effect.value * units
	return 1.0 + result if effect.op == "scale" else result

static func apply(before: float, effect: Dictionary, value: float) -> float:
	return before + value if effect.op == "add" else before * value
