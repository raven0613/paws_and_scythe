extends RefCounted

# 過關獎勵：每關固定 BASE；速通獎勵為過關當下每次剩餘結算給 SPEED_PER_SETTLEMENT。
# 利息以過關當下、加入本關獎勵前的持有金錢計算，每 INTEREST_STEP 元給 1 元，最多 INTEREST_CAP 元。
const BASE = 3
const SPEED_PER_SETTLEMENT = 1
const INTEREST_STEP = 5
const INTEREST_CAP = 4
