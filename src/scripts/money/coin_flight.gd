extends Control

const Config = preload("res://src/configs/money/money_motion_config.gd")

var _coins: Array = []
var _sparks: Array = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = Config.COIN_LAYER
	_rng.randomize()
	set_process(false)

# 金幣從 source 噴出後飛入 target；每枚抵達時呼叫 landed(index, count)，最後一枚的 index 為 count - 1。
func launch(source: Vector2, target: Vector2, amount: int, landed: Callable) -> void:
	var count := clampi(amount, 1, Config.MAX_COINS)
	var inverse := get_global_transform().affine_inverse()
	for index in count:
		var burst := Vector2(_rng.randf_range(-1.0, 1.0) * Config.BURST_RADIUS.x, -_rng.randf_range(0.3, 1.0) * Config.BURST_RADIUS.y)
		_coins.append({
			"source": inverse * source, "target": inverse * target, "burst": burst,
			"time": -index * Config.STAGGER, "spin": _rng.randf() * TAU,
			"index": index, "count": count, "landed": landed,
		})
	set_process(true)

func clear() -> void:
	_coins.clear()
	_sparks.clear()
	set_process(false)
	queue_redraw()

func _process(delta: float) -> void:
	var duration := Config.BURST_DURATION + Config.TRAVEL_DURATION
	for coin in _coins:
		coin.time += delta
	for coin in _coins.filter(func(item): return item.time >= duration):
		_coins.erase(coin)
		_sparks.append({"position": coin.target, "time": 0.0})
		coin.landed.call(coin.index, coin.count)
	for spark in _sparks:
		spark.time += delta
	_sparks = _sparks.filter(func(item): return item.time < Config.SPARK_DURATION)
	set_process(not (_coins.is_empty() and _sparks.is_empty()))
	queue_redraw()

func _draw() -> void:
	for coin in _coins:
		if coin.time >= 0.0:
			_draw_coin(_position(coin), absf(cos(coin.spin + coin.time * Config.SPIN_SPEED)))
	for spark in _sparks:
		var progress: float = spark.time / Config.SPARK_DURATION
		var color := Config.COIN_SHINE
		color.a = 1.0 - progress
		draw_arc(spark.position, Config.SPARK_RADIUS * progress, 0.0, TAU, Config.SPARK_SEGMENTS, color, Config.SPARK_WIDTH)

# 噴出段以 Back Out 衝出，飛行段以二次方加速，沿高於兩端中點 ARC_HEIGHT 的弧線吸入目標。
func _position(coin: Dictionary) -> Vector2:
	var source: Vector2 = coin.source
	var burst: Vector2 = coin.burst
	if coin.time < Config.BURST_DURATION:
		var pop: float = Tween.interpolate_value(0.0, 1.0, coin.time, Config.BURST_DURATION, Tween.TRANS_BACK, Tween.EASE_OUT)
		return source + burst * pop
	var start := source + burst
	var target: Vector2 = coin.target
	var travel: float = pow((coin.time - Config.BURST_DURATION) / Config.TRAVEL_DURATION, 2)
	var control := (start + target) / 2 + Vector2.UP * Config.ARC_HEIGHT
	return start.lerp(control, travel).lerp(control.lerp(target, travel), travel)

# 金幣以寬度變化模擬翻面，外框、填色與高光依序疊畫。
func _draw_coin(center: Vector2, face: float) -> void:
	var width := Config.COIN_SIZE * maxf(face, Config.COIN_MIN_WIDTH)
	var rect := Rect2(center - Vector2(width, Config.COIN_SIZE) / 2, Vector2(width, Config.COIN_SIZE))
	draw_rect(rect.grow(1.0), Config.COIN_EDGE)
	draw_rect(rect, Config.COIN_COLOR)
	draw_rect(Rect2(rect.position + Vector2.ONE, Vector2(maxf(width / 3, 1.0), 2.0)), Config.COIN_SHINE)
