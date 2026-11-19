extends RefCounted

# 關卡曲線探針：模擬玩家依構築路線在每次過關後購買貓牌，各關建議目標取所有模擬玩家
# 第 CLEAR_TURNS 次結算累積分數的中位數；小數表示在相鄰兩次結算的累積分數之間線性取值。
const CLEAR_TURNS = [
	3.0, 3.0, 3.0, 3.0, 3.0, 3.0,
	4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0,
	4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0,
]
# spend 買得起就買；save 保留可拿滿利息的持有金額，只花超出的部分。
const STRATEGIES = ["spend", "save"]
const SAMPLES = 8
const SEED = 72603
# 建議目標取整：低於 SMALL_LIMIT 以 SMALL_STEP 為單位，低於 MEDIUM_LIMIT 以 MEDIUM_STEP 為單位，其餘以 LARGE_STEP 為單位。
const SMALL_LIMIT = 1000
const SMALL_STEP = 50
const MEDIUM_LIMIT = 10000
const MEDIUM_STEP = 100
const LARGE_STEP = 500
