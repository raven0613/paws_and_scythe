extends RefCounted

const Config = preload("res://src/configs/run_records/record_config.gd")

static func save(document: Dictionary, directory: String = Config.DIRECTORY) -> Error:
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return error
	var path := directory.path_join(document.run_id + ".json")
	error = write_json(path + ".tmp", document)
	if error != OK:
		return error
	return DirAccess.rename_absolute(path + ".tmp", path)

static func write_json(path: String, document: Dictionary) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(document, "\t", false, true))
	file.flush()
	var error := file.get_error()
	file.close()
	return error
