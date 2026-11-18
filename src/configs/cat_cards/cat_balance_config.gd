extends RefCounted

# 貓牌產出探針與關卡曲線探針共用的構築路線，依購買順序排列。
const BUILDS = {
	"steady": ["peace", "matching", "combo", "growth", "crossing"],
	"pairs": ["matching", "pairs", "crossing", "small", "growth"],
	"variety": ["variety", "alternating", "crossing", "unique", "combo"],
	"solo": ["suited", "long", "solo", "copy", "reserve"],
}
const PROBE_COUNTS = [0, 1, 2, 3, 4, 5]
const PROBE_SAMPLES = 8
const REPORT_TURNS = [3, 4, 5, 6]
