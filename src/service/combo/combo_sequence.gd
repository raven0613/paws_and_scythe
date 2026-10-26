@tool
extends RefCounted

const Config = preload("res://src/configs/combo/combo_config.gd")

var _rng := RandomNumberGenerator.new()
var _frames: Array[int] = []
var _offsets: Array[int] = []


func reset(seed_value: int) -> void:
	_rng.seed = seed_value
	_frames.clear()
	_offsets.clear()
	_ensure_length(Config.INITIAL_SEQUENCE_LENGTH)


func get_layout(index: int) -> Dictionary:
	_ensure_length(index + 1)
	return {"frame_index": _frames[index], "offset_x": _offsets[index]}


func _ensure_length(length: int) -> void:
	while _frames.size() < length:
		var previous_frame: int = -1 if _frames.is_empty() else _frames.back()
		var previous_offset: int = Config.OFFSET_MIN - 1 if _offsets.is_empty() else _offsets.back()
		_frames.append(_pick_except(0, Config.FRAME_PATHS.size() - 1, previous_frame))
		_offsets.append(_pick_except(Config.OFFSET_MIN, Config.OFFSET_MAX, previous_offset))


func _pick_except(minimum: int, maximum: int, previous: int) -> int:
	if minimum == maximum:
		return minimum
	if previous < minimum or previous > maximum:
		return _rng.randi_range(minimum, maximum)
	var result := _rng.randi_range(minimum, maximum - 1)
	return result + 1 if result >= previous else result
