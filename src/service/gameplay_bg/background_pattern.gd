@tool
extends RefCounted

const Config = preload("res://src/configs/gameplay_bg/gameplay_bg_config.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]

var grid_size := Vector2i.ZERO
var tiles := PackedInt32Array()


func build(max_run: int, minimum: int, seed_value: int, extra_chance: float) -> bool:
	if max_run < 1 or minimum < 0 or minimum > Config.DENSITY_WINDOW.x * Config.DENSITY_WINDOW.y:
		return false
	# 從已符合限制的環狀排列開始，再隨機疏開，保證產生過程會結束。
	var found := false
	for period in range(2, max_run + 2):
		var side := ceili(float(Config.MIN_PATTERN_SIDE) / (period * 2)) * period * 2
		grid_size = Vector2i(side, side)
		tiles.resize(side * side)
		for y in side:
			for x in side:
				tiles[y * side + x] = int((x + y) % period != 0)
		if _all_windows_meet(minimum):
			found = true
			break
	if not found:
		tiles.clear()
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var order := _shuffled_indices(rng)
	for index in order:
		if tiles[index] == 0:
			continue
		var cell := Vector2i(index % grid_size.x, index / grid_size.x)
		tiles[index] = 0
		if not _affected_windows_meet(cell, minimum):
			tiles[index] = 1
	for index in _shuffled_indices(rng):
		if tiles[index] != 0 or rng.randf() >= extra_chance:
			continue
		var cell := Vector2i(index % grid_size.x, index / grid_size.x)
		if _can_add(cell, max_run):
			tiles[index] = 1
	_color_faces(rng)
	return true


func tile_at(cell: Vector2i) -> int:
	return tiles[posmod(cell.y, grid_size.y) * grid_size.x + posmod(cell.x, grid_size.x)]


func _window_count(origin: Vector2i) -> int:
	var count := 0
	for y in Config.DENSITY_WINDOW.y:
		for x in Config.DENSITY_WINDOW.x:
			count += int(tile_at(origin + Vector2i(x, y)) > 0)
	return count


func _all_windows_meet(minimum: int) -> bool:
	for y in grid_size.y:
		for x in grid_size.x:
			if _window_count(Vector2i(x, y)) < minimum:
				return false
	return true


func _affected_windows_meet(cell: Vector2i, minimum: int) -> bool:
	for y in Config.DENSITY_WINDOW.y:
		for x in Config.DENSITY_WINDOW.x:
			if _window_count(cell - Vector2i(x, y)) < minimum:
				return false
	return true


func _can_add(cell: Vector2i, max_run: int) -> bool:
	for direction in DIRECTIONS:
		var run_length := 1
		for sign_value in [-1, 1]:
			for step in range(1, max_run + 1):
				if tile_at(cell + direction * step * sign_value) == 0:
					break
				run_length += 1
		if run_length > max_run:
			return false
	return true


func _color_faces(rng: RandomNumberGenerator) -> void:
	# 偶數邊長讓棋盤兩色在首尾接縫也相容，再隨機換成可用貓臉。
	for y in grid_size.y:
		for x in grid_size.x:
			var index := y * grid_size.x + x
			if tiles[index] > 0:
				tiles[index] = 1 + (x + y) % 2
	for index in _shuffled_indices(rng):
		if tiles[index] == 0:
			continue
		var cell := Vector2i(index % grid_size.x, index / grid_size.x)
		var choices: Array[int] = []
		for face in range(1, Config.TEXTURE_PATHS.size()):
			var allowed := true
			for direction in DIRECTIONS:
				if tile_at(cell + direction) == face or tile_at(cell - direction) == face:
					allowed = false
			if allowed:
				choices.append(face)
		tiles[index] = choices[rng.randi_range(0, choices.size() - 1)]


func _shuffled_indices(rng: RandomNumberGenerator) -> Array[int]:
	var order: Array[int] = []
	for index in tiles.size():
		order.append(index)
	for index in range(order.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var previous := order[index]
		order[index] = order[other]
		order[other] = previous
	return order
