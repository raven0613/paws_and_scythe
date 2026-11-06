extends RefCounted

const GROUP_COLORS = {
	"straight": Color("69b8da"), "flush": Color("b088cf"),
	"full_house": Color("e0b871"), "four": Color("df8b80"), "straight_flush": Color("86cfba"),
}

static func number(value: float) -> String:
	return str(roundi(value))

static func multiplier(value: float) -> String:
	return ("%.2f" % value).trim_suffix("0") if is_equal_approx(value * 10, round(value * 10)) else "%.2f" % value

static func precise(value: float) -> String:
	return ("%.2f" % value).trim_suffix("0").trim_suffix("0").trim_suffix(".")
