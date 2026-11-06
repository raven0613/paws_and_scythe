extends RefCounted

# 0→5 張的曲線基準；開局選牌是構築試玩入口。
const EXPECTED_COUNTS = [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 5, 5, 5]
const BUILDS = {
	"steady": ["peace", "matching", "combo", "growth", "crossing"],
	"pairs": ["matching", "pairs", "crossing", "small", "growth"],
	"variety": ["variety", "alternating", "crossing", "unique", "combo"],
	"solo": ["suited", "long", "solo", "copy", "reserve"],
}
const PROBE_COUNTS = [0, 1, 2, 3, 4, 5]
const PROBE_SAMPLES = 8
const TARGET_TEST_LEVELS = [3, 6, 9, 12, 15, 21]
const REPORT_TURNS = [3, 4, 5, 6]
