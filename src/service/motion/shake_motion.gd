extends RefCounted

# 衰減抖動：progress 由 0 到 1，橫向與旋轉共用 cycles 的波形，縱向使用 vertical_cycles，
# 振幅依 decay_power 衰減，progress 為 1 時位移與旋轉回到零；decay 供呼叫端讓起始偏移一起收斂。
static func pose(progress: float, shake: Vector2, tilt: float, cycles: float, vertical_cycles: float, decay_power: float) -> Dictionary:
	var decay := pow(1.0 - progress, decay_power)
	var wave := sin(progress * TAU * cycles)
	var vertical := sin(progress * TAU * vertical_cycles)
	return {"decay": decay, "position": shake * Vector2(wave, vertical) * decay, "rotation": tilt * wave * decay}
