extends SceneTree

const Config = preload("res://src/configs/combo/combo_config.gd")
const Sequence = preload("res://src/service/combo/combo_sequence.gd")

var failures := 0


func _init() -> void:
	for seed_offset in Config.TEST_SEED_COUNT:
		var sequence = Sequence.new()
		sequence.reset(Config.EDITOR_SEED + seed_offset)
		var snapshot: Array[Dictionary] = []
		var previous_frame := -1
		var previous_offset := Config.OFFSET_MIN - 1
		for index in Config.INITIAL_SEQUENCE_LENGTH * 3:
			var layout: Dictionary = sequence.get_layout(index)
			_check(layout.frame_index >= 0 and layout.frame_index < Config.FRAME_PATHS.size(), "Every frame must reference an existing shape.")
			_check(layout.frame_index != previous_frame, "Adjacent shapes must differ, including sequence extensions.")
			_check(layout.offset_x >= Config.OFFSET_MIN and layout.offset_x <= Config.OFFSET_MAX, "Offsets must stay within config bounds.")
			if Config.OFFSET_MIN < Config.OFFSET_MAX:
				_check(layout.offset_x != previous_offset, "Adjacent rows must not align exactly.")
			snapshot.append(layout)
			previous_frame = layout.frame_index
			previous_offset = layout.offset_x
		for index in range(snapshot.size() - 1, -1, -1):
			_check(sequence.get_layout(index) == snapshot[index], "Re-reading indices must preserve existing layouts.")
		sequence.reset(Config.EDITOR_SEED + seed_offset)
		for index in snapshot.size():
			_check(sequence.get_layout(index) == snapshot[index], "A reset must reproduce a sequence when given the same seed.")
	var direct = Sequence.new()
	var incremental = Sequence.new()
	direct.reset(Config.EDITOR_SEED)
	incremental.reset(Config.EDITOR_SEED)
	var target := Config.INITIAL_SEQUENCE_LENGTH * 2
	var expected: Dictionary = direct.get_layout(target)
	for index in target:
		incremental.get_layout(index)
	_check(incremental.get_layout(target) == expected, "Growth must preserve the sequence regardless of access order.")
	if failures == 0:
		print("Combo sequence passed: distinct neighbors, bounded offsets, stable indices and deterministic extension/reset.")
	quit(int(failures > 0))


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
