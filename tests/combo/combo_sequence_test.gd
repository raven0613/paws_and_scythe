extends SceneTree

const Config = preload("res://src/configs/combo/combo_config.gd")
const Sequence = preload("res://src/service/combo/combo_sequence.gd")
var failures := 0

func _init() -> void:
	for seed_offset in Config.TEST_SEED_COUNT:
		var sequence = Sequence.new()
		sequence.reset(Config.EDITOR_SEED + seed_offset)
		var original: Array = sequence.resolve([], [-1, -1, -1])
		_check_neighbors(original)
		var snapshot: Array = original.duplicate(true)
		var inserted: Array = sequence.resolve(original, [0, -1, -1, 1, 2])
		_check(inserted[0] == original[0] and inserted[3] == original[1] and inserted[4] == original[2], "Insertion preserves existing appearances and offsets.")
		_check_neighbors(inserted)
		_check(inserted[1].frame_index != original[1].frame_index, "The first of several arriving rows also avoids the next existing visible shape.")
		_check(sequence.resolve(inserted, [0, 1, 2, 3, 4]) == inserted, "Settlement-style refresh preserves all appearances.")
		_check(sequence.resolve(inserted, [4, 0]) == [original[2], original[0]], "Removal and reordering retain each appearance.")
		_check(original == snapshot, "Allocation keeps the source layouts intact.")
		sequence.reset(Config.EDITOR_SEED + seed_offset)
		_check(sequence.resolve([], [-1, -1, -1]) == original, "Seeded generation is reproducible.")
		for left in Config.FRAME_PATHS.size():
			for right in Config.FRAME_PATHS.size():
				var neighbors := [{"frame_index": left, "offset_x": Config.OFFSET_MIN}, {"frame_index": right, "offset_x": Config.OFFSET_MAX}]
				var middle: Array = sequence.resolve(neighbors, [0, -1, 1])
				_check(middle[1].frame_index != left and middle[1].frame_index != right, "A new middle row avoids both neighboring shapes.")
				_check(middle[0] == neighbors[0] and middle[2] == neighbors[1], "Existing neighbors stay unchanged, including equal shapes.")
	if failures == 0:
		print("Combo appearance passed: stable identity, neighbor exclusion, removal and deterministic generation.")
	quit(int(failures > 0))

func _check_neighbors(layouts: Array) -> void:
	for index in layouts.size():
		var layout: Dictionary = layouts[index]
		_check(layout.frame_index >= 0 and layout.frame_index < Config.FRAME_PATHS.size(), "Shape comes from config.")
		_check(layout.offset_x >= Config.OFFSET_MIN and layout.offset_x <= Config.OFFSET_MAX, "Offset stays within config bounds.")
		if index > 0:
			_check(layout.frame_index != layouts[index - 1].frame_index, "New adjacent rows use different shapes.")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
