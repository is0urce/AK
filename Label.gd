extends Node

enum DocumentState { INITIALIZING, CLEAN, DIRTY, INVALID }

var categories_container : Container
var current_url : String
var load_url : String
var state : DocumentState = DocumentState.CLEAN
var original_data : Dictionary
var data : Dictionary
var dirty : bool = false
var confirmation_dialog : ConfirmationDialog

# Called when the node enters the scene tree for the first time.
func _ready():
	categories_container = get_parent().find_child("CategoriesContainer") as Container
	if !categories_container:
		print("ERROR: cannot find categories container")

func _on_select_source(url : String):
	if url == current_url:
		return
	if !open_document(url):
		return
	current_url = url
	
func _on_save():
	save_document(current_url)
	
func _on_save_as(url : String):
	save_document(url)

func _on_save_and_exit():
	if !save_document(current_url):
		return
	get_tree().quit()

func _on_save_and_load():
	if !save_document(current_url):
		return
	open_document(load_url)
	
func _on_close():
	if state == DocumentState.DIRTY:
		var confirmation = get_confirmation_dialog()
		var e = confirmation.connect("confirmed", "_on_save_and_exit")
		if e != OK:
			print("ERROR: connect confirmation event")
		confirmation.popup()
		return
	close_document()

func get_confirmation_dialog():
	if !confirmation_dialog:
		confirmation_dialog = ConfirmationDialog.new()
		confirmation_dialog.dialog_text = "SAVE?"
		add_child(confirmation_dialog)
		return confirmation_dialog

func disconnect_from_me(node):
	var signals = node.g1et_signal_list()
	for s in signals:
		var connections = node.get_signal_connection_list(s.name)
		for connection in connections:
			node.disconnect(s.signal, connection.target, connection.method)
			
func add_category(category : String):
	var button = Button.new();
	button.text = category
	categories_container.add_child(button)

func populate_categories(content : Dictionary):
	if !content.has("categories"):
		print("WARNING: no categories in the database")
		return
	var categories = content["categories"] as Dictionary
	if !categories:
		print("WARNING: no categories in the database")
		return
	for category in categories.keys():
		add_category(category)
		
func clear_categories():
	var categories = categories_container.get_children()
	for category in categories:
		category.queue_free()

func populate_hints(_content : Dictionary):
	pass

func close_document():
	state = DocumentState.CLEAN
	data.clear()
	dirty = false
	clear_categories()
	return true

func open_document(url : String):
	close_document()
	if url.is_empty():
		print("ERROR: url is empty, url=" + url)
	var file = FileAccess.open(url, FileAccess.READ)
	if !file.is_open():
		print("ERROR: file cannot be opened, path=" + url)
		return false
	var text = file.get_as_text()
	if text.is_empty():
		print("ERROR: file is empty, path=" + url)
		return false
	var json = JSON.new()
	if json.parse(text) != OK:
		print("ERROR: invalid json"
			+ " parse failed on line " + String.num_int64(json.get_error_line())
			+ " with a message: " + json.get_error_message())
		return false
	select(url, json.data)
	return true

func save_document(url : String):
	if url.is_empty():
		#todo: save new
		return false
	var text = JSON.stringify(data, "", true, true)
	var file = FileAccess.open(url, FileAccess.WRITE)
	if !file.is_open():
		print("ERROR: cannot open file for writing, url=" + url)
		return false
	file.store_string(text)
	return true

func select(url : String, content : Dictionary):
	DisplayServer.window_set_title(url)
	data = content
	original_data = data.duplicate(true)
	state = DocumentState.CLEAN
	populate_categories(data)
	populate_hints(data)
