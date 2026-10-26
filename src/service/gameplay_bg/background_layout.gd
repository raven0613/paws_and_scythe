@tool
extends RefCounted

const Config = preload("res://src/configs/gameplay_bg/gameplay_bg_config.gd")


static func advance_phase(phase: Vector2, delta: float, grid_size: Vector2i) -> Vector2:
	var movement := Config.SCROLL_DIRECTION.normalized() * Config.SCROLL_SPEED * delta
	var rows := movement.y / Config.ROW_STEP.y
	var columns := (movement.x - rows * Config.ROW_STEP.x) / Config.COLUMN_STEP.x
	return Vector2(
		fposmod(phase.x + columns, grid_size.x),
		fposmod(phase.y + rows, grid_size.y)
	)


static func visible_cells(phase: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var offset := Config.ORIGIN + phase.x * Config.COLUMN_STEP + phase.y * Config.ROW_STEP
	var first_row := floori(-offset.y / Config.ROW_STEP.y) - 1
	var last_row := ceili((Config.REFERENCE_SIZE.y - offset.y) / Config.ROW_STEP.y) + 1
	for row in range(first_row, last_row + 1):
		var row_origin := offset + row * Config.ROW_STEP
		var first_column := floori(-row_origin.x / Config.COLUMN_STEP.x) - 1
		var last_column := ceili((Config.REFERENCE_SIZE.x - row_origin.x) / Config.COLUMN_STEP.x)
		for column in range(first_column, last_column + 1):
			result.append({
				"cell": Vector2i(column, row),
				"position": (row_origin + column * Config.COLUMN_STEP).round(),
			})
	return result
