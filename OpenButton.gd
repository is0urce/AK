extends Button

var file_dialog

signal file_selected

# Called when the node enters the scene tree for the first time.

func get_file_dialog():
	if !file_dialog:
		file_dialog = FileDialog.new()
		add_child(file_dialog)
		file_dialog.mode_overrides_title = true
		file_dialog.mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.filters = PackedStringArray(["*.json ; JSON Files"])
		file_dialog.connect("file_selected", _file_selected)
		file_dialog.current_dir = "I:/program/godot/json"
	return file_dialog

func _pressed():
	file_dialog = get_file_dialog()
	file_dialog.set_size(DisplayServer.window_get_size())
	get_file_dialog().popup()

func _file_selected(path : String):
	if path.is_empty():
		print("ERROR: selected file path is empty")
	#print("Dir selected: " + path)
	file_selected.emit(path)
