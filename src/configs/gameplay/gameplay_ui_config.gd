extends RefCounted

const GROUP_COLORS = {
	"straight": Color("69b8da"), "flush": Color("b088cf"),
	"full_house": Color("e0b871"), "four": Color("df8b80"), "straight_flush": Color("86cfba"),
}

static func number(value: float) -> String:
	return str(roundi(value))

static func multiplier(value: float) -> String:
	return "%.1f" % value
