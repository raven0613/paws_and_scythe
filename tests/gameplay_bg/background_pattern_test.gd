extends SceneTree

const Config = preload("res://src/configs/gameplay_bg/gameplay_bg_config.gd")
const Frame = preload("res://src/configs/gameplay/gameplay_frame_config.gd")
const Pattern = preload("res://src/service/gameplay_bg/background_pattern.gd")
const Layout = preload("res://src/service/gameplay_bg/background_layout.gd")

var failures: int = 0


func _init() -> void:
	for max_run in Config.TEST_RUN_LIMITS:
		for minimum in Config.TEST_MINIMUMS:
			# 每格都必須與一般方塊交錯時，六格視窗最多只能放三隻貓。
			if max_run == 1 and minimum > Config.DENSITY_WINDOW.x:
				continue
			for seed_offset in Config.TEST_SEED_COUNT:
				var pattern = Pattern.new()
				_check(pattern.build(max_run, minimum, Config.SEED + seed_offset, Config.EXTRA_CAT_CHANCE),
					"Valid distribution settings must generate a pattern.")
				if pattern.tiles.is_empty():
					continue
				_check_rules(pattern, max_run, minimum)
	var pattern = Pattern.new()
	_check(pattern.build(Config.MAX_CONSECUTIVE_CATS, Config.MIN_CATS_PER_SCREEN,
		Config.SEED, Config.EXTRA_CAT_CHANCE), "Default pattern must generate.")
	if not pattern.tiles.is_empty():
		_check_visible_density(pattern)
		_check_seams(pattern)
		_check_movement(pattern)
		var duplicate = Pattern.new()
		duplicate.build(Config.MAX_CONSECUTIVE_CATS, Config.MIN_CATS_PER_SCREEN,
			Config.SEED, Config.EXTRA_CAT_CHANCE)
		_check(pattern.tiles == duplicate.tiles, "A fixed seed must reproduce the same pattern.")
	if failures == 0:
		print("Background logic passed: density, runs, distinct adjacent faces, seams and scrolling.")
	quit(int(failures > 0))


func _check_rules(pattern, max_run: int, minimum: int) -> void:
	for y in pattern.grid_size.y:
		for x in pattern.grid_size.x:
			var cell := Vector2i(x, y)
			var face: int = pattern.tile_at(cell)
			_check(face >= 0 and face < Config.TEXTURE_PATHS.size(), "Every tile must use an existing texture.")
			var count := 0
			for dy in Config.DENSITY_WINDOW.y:
				for dx in Config.DENSITY_WINDOW.x:
					count += int(pattern.tile_at(cell + Vector2i(dx, dy)) > 0)
			_check(count >= minimum, "Each density window must meet the minimum, including wrapped windows.")
			for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
				var run_length := 0
				for step in range(max_run + 1):
					if pattern.tile_at(cell + direction * step) == 0:
						break
					run_length += 1
				_check(run_length <= max_run, "Cat runs must respect the configured limit across seams.")
				if face > 0:
					_check(face != pattern.tile_at(cell + direction), "Adjacent cat faces must differ.")


func _check_visible_density(pattern) -> void:
	for y in Config.TEST_PHASE_STEPS:
		for x in Config.TEST_PHASE_STEPS:
			var phase := Vector2(x, y) * Vector2(pattern.grid_size) / Config.TEST_PHASE_STEPS
			var count := 0
			for item in Layout.visible_cells(phase):
				if pattern.tile_at(item.cell) == 0:
					continue
				var face_rect := Rect2(item.position + Config.CAT_FACE_BOUNDS.position, Config.CAT_FACE_BOUNDS.size)
				if Frame.CLEAR_RECT.encloses(face_rect):
					count += 1
			_check(count >= Config.MIN_CATS_PER_SCREEN, "Fully visible faces inside the frame must meet the minimum while scrolling.")


func _check_seams(pattern) -> void:
	var initial := _visible_signature(pattern, Vector2.ZERO)
	_check(initial == _visible_signature(pattern, Vector2(pattern.grid_size.x, 0)), "Horizontal loop must preserve all visible tiles.")
	_check(initial == _visible_signature(pattern, Vector2(0, pattern.grid_size.y)), "Slanted row loop must preserve all visible tiles.")


func _visible_signature(pattern, phase: Vector2) -> Dictionary:
	var signature := {}
	for item in Layout.visible_cells(phase):
		signature[item.position] = pattern.tile_at(item.cell)
	return signature


func _check_movement(pattern) -> void:
	var phase := Vector2.ONE
	var advanced := Layout.advance_phase(phase, 1.0, pattern.grid_size)
	var difference := advanced - phase
	var displacement: Vector2 = difference.x * Config.COLUMN_STEP + difference.y * Config.ROW_STEP
	var expected: Vector2 = Config.SCROLL_DIRECTION.normalized() * Config.SCROLL_SPEED
	_check(displacement.is_equal_approx(expected), "Scrolling must follow the tile slope at the configured speed.")
	_check(displacement.x < 0.0 and displacement.y > 0.0, "Scrolling must travel down and left.")
	for step in Config.TEST_PHASE_STEPS:
		phase = Layout.advance_phase(phase, Config.TEST_PHASE_STEPS, pattern.grid_size)
		_check(phase.x >= 0 and phase.x < pattern.grid_size.x and phase.y >= 0 and phase.y < pattern.grid_size.y,
			"Loop phase must remain bounded over time.")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
