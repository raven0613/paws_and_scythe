@tool
extends RefCounted

const Config = preload("res://src/configs/combo/combo_config.gd")
var _rng := RandomNumberGenerator.new()

func reset(seed_value: int) -> void:
	_rng.seed = seed_value

# 先保留延續列的外觀，再替新列選擇與兩側不同的造型。
func resolve(previous: Array, source_indices: Array) -> Array[Dictionary]:
	var layouts: Array[Dictionary] = []
	for source in source_indices:
		layouts.append(previous[source].duplicate() if source >= 0 else {})
	for index in layouts.size():
		if not layouts[index].is_empty():
			continue
		var neighbors: Array = []
		if index > 0:
			neighbors.append(layouts[index - 1])
		for right in range(index + 1, layouts.size()):
			if not layouts[right].is_empty():
				neighbors.append(layouts[right])
				break
		layouts[index] = {
			"frame_index": _choose(range(Config.FRAME_PATHS.size()), neighbors, "frame_index"),
			"offset_x": _choose(range(Config.OFFSET_MIN, Config.OFFSET_MAX + 1), neighbors, "offset_x"),
		}
	return layouts

func _choose(options: Array, neighbors: Array, key: String) -> int:
	for neighbor in neighbors:
		options.erase(neighbor[key])
	return options[_rng.randi_range(0, options.size() - 1)]
