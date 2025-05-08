extends RefCounted

static var indent_type: int = 0
static var indent_size: int = 4

static var line_column: int
static var split_line: PackedStringArray
static var split_size: int 
static var signal_name: String
static var object_type: String
static var object_name: String
static var signal_args: Array[Dictionary]
static var inset_args_text: String
static var callable_name: String
static var inset_func_text: String

static func init(type: int, size: int) -> void:
	indent_type = type
	indent_size = size

static func indent_is_tab() -> bool:
	return indent_type == 0

static func indent_is_space() -> bool:
	return indent_type == 1

static func parse_line(line: String) -> bool:
	line_column = line.length() - 1
	if indent_is_tab():
		split_line = line.strip_escapes().split(".")
	elif indent_is_space():
		split_line = line.lstrip(" ").split(".")
	
	split_size = split_line.size()
	if split_size <= 1:
		return false
	
	if split_size == 2:
		if (
				split_line.get(0).contains("$")
				or split_line.get(0).contains("%")
		):
			return false
		
	# The '1' is 'connect()' part in 'split_line'
	signal_name = split_line.get(split_size - 2)
	return true

static func is_comment(edit: CodeEdit, line: int) -> bool:
	return edit.is_in_comment(line) != -1

static func has_connect() -> bool:
	return split_line.has("connect()")

static func caret_is_on_connect(edit: CodeEdit) -> bool:
	var caret_column: int = edit.get_caret_column()
	return line_column == caret_column

static func is_self() -> bool:
	return split_line.has("self")

static func get_property(script: Script, name: String) -> Dictionary:
	var property_list: Array[Dictionary] = script.get_script_property_list()
	if property_list.size() <= 1:
		return {}
	
	for i: int in range(1, property_list.size()):
		var property := property_list.get(i) as Dictionary
		if property.get("name") == name:
			return property
		
	return {}

static func is_var(script: Script, name: String) -> bool:
	return not get_property(script, name).is_empty()

static func is_node_path() -> bool:
	return split_line.get(0).contains("$") or split_line.get(0).contains("%")

static func get_var_type(script: Script, name: String, node: Node) -> String:
	var property: Dictionary = get_property(script, name)
	var _class_name := property.get("class_name") as StringName
	object_name = property.get("name") as String
	if not _class_name.is_empty():
		return _class_name
	
	var property_list: Array[Dictionary] = script.get_script_property_list()
	property = property_list.get(0) as Dictionary
	var hint_string: String = property.get("hint_string")
	var file := FileAccess.open(hint_string, FileAccess.READ)
	var caret_line: int = 0
	var current_line: String
	while not file.eof_reached():
		current_line = file.get_line()
		if current_line.contains("var %s" % name):
			break
		
		caret_line += 1
	
	var from: int = current_line.find("$") if current_line.find("%") == -1 else current_line.find("%")
	var node_path: NodePath = current_line.substr(from + 1)
	if node.has_node(node_path):
		var new_node: Node = node.get_node(node_path)
		object_name = new_node.name.to_snake_case()
		_class_name = new_node.get_class()
	return _class_name

static func get_node_path_type(node: Node) -> String:
	var _class_name: String
	var node_path: NodePath = split_line.get(0).substr(1)
	if node.has_node(node_path):
		var new_node: Node = node.get_node(node_path)
		object_name = new_node.name.to_snake_case()
		_class_name = new_node.get_class()
	return _class_name

static func find_object_type(editor: ScriptEditor, editor_interface: EditorInterface) -> bool:
	var script: Script = editor.get_current_script()
	match split_size:
		2:
			object_type = (
				script.get_instance_base_type()
				if script.get_global_name().is_empty()
				else script.get_global_name()
			)
			object_name = object_type.to_snake_case()
			return true
		3 when is_self():
			object_type = (
				script.get_instance_base_type()
				if script.get_global_name().is_empty()
				else script.get_global_name()
			)
			object_name = object_type.to_snake_case()
			return true
		3 when is_var(script, split_line.get(0)):
			var scene_root: Node = editor_interface.get_edited_scene_root()
			object_type = get_var_type(script, split_line.get(0), scene_root)
			return true
		3 when is_node_path():
			var scene_root: Node = editor_interface.get_edited_scene_root()
			object_type = get_node_path_type(scene_root)
			return true
	return false

static func find_signal_args(script_editor: ScriptEditor) -> void:
	var signal_data: Dictionary = ClassDB.class_get_signal(object_type, signal_name)
	if signal_data.is_empty():
		var signal_list: Array[Dictionary] = script_editor.get_current_script().get_script_signal_list()
		for i: int in signal_list.size():
			signal_data = signal_list.get(i)
			if signal_data.get("name") == signal_name:
				break
			signal_data = {}
	
	if signal_data.get("args") is Array:
		signal_args = signal_data.get("args") as Array
	
	if signal_args.is_empty():
		return
	
	var signal_args_size: int = signal_args.size()
	for arg: Dictionary in signal_args:
		var name := arg.get("name") as String 
		var _class_name := arg.get("class_name") as StringName
		var type := type_string(arg.get("type")) as String
		if _class_name.is_empty():
			inset_args_text += "%s: %s, " % [name, type]
		else :
			inset_args_text += "%s: %s, " % [name, _class_name]
	var from: int = inset_args_text.rfind(", ")
	inset_args_text = inset_args_text.substr(0, from)

static func get_lambda_text(current_line: String) -> String:
	if indent_is_tab():
		var tabs: int = current_line.count("\t")
		var text: String = "func (%s):\n%spass\n%s" % [
			inset_args_text,
			"\t".repeat(tabs + 1),
			"\t".repeat(tabs)
		]
		return text
	elif indent_is_space():
		var spaces: int = current_line.count(" ")
		var text: String = "func (%s):\n%spass\n%s" % [
			inset_args_text,
			" ".repeat(spaces + indent_size),
			" ".repeat(spaces)
		]
		return text
	return ""

static func get_method_text(current_line: String) -> String:
	if indent_is_tab():
		var tabs: int = current_line.count("\t")
		if is_self() or split_size == 2:
			callable_name = "_on_%s" % signal_name
		else :
			callable_name = "_on_%s_%s" % [object_name, signal_name]
		var text: String = "\nfunc %s(%s) -> void:\n%spass" % [
			callable_name,
			inset_args_text,
			"\t".repeat(tabs)
		]
		inset_func_text = text
		return text
	elif indent_is_space():
		var spaces: int = current_line.count(" ")
		if is_self() or split_size == 2:
			callable_name = "_on_%s" % signal_name
		else :
			callable_name = "_on_%s_%s" % [object_name, signal_name]
		var text: String = "\nfunc %s(%s) -> void:\n%spass" % [
			callable_name,
			inset_args_text,
			" ".repeat(spaces)
		]
		inset_func_text = text
		return text
	
	return ""

static func clear() -> void:
	line_column = 0
	split_line.clear()
	split_size = 0
	object_type = ""
	object_name = ""
	signal_args.clear()
	inset_args_text = ""
