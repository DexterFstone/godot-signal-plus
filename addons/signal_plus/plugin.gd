@tool
extends EditorPlugin

const GDScriptParser = preload("res://addons/signal_plus/gdscript_parser.gd")

var main_screen_name: String

var editor_settings: EditorSettings
var script_editor: ScriptEditor
var script_editor_base: ScriptEditorBase
var base_editor: CodeEdit
var indent_type: int = 0
var indent_size: int = 4

@onready var method_icon: Resource = (
		get_editor_interface().get_editor_theme().get_icon("MethodOverride", "EditorIcons")
)

@onready var lambda_icon: Resource = (
		get_editor_interface().get_editor_theme().get_icon("MethodOverrideAndSlot", "EditorIcons")
)

func _enter_tree() -> void:
	main_screen_changed.connect(_on_main_screen_changed)
	get_editor_interface().set_main_screen_editor("2D")
	get_editor_interface().set_main_screen_editor("Script")
	editor_settings = get_editor_interface().get_editor_settings()
	if not editor_settings.settings_changed.is_connected(_on_editor_settings_settings_changed):
		editor_settings.settings_changed.connect(_on_editor_settings_settings_changed)
	indent_type = editor_settings.get_setting("text_editor/behavior/indent/type")
	indent_size = editor_settings.get_setting("text_editor/behavior/indent/size")
	script_editor = get_editor_interface().get_script_editor()
	if not script_editor.editor_script_changed.is_connected(_on_editor_script_changed):
		script_editor.editor_script_changed.connect(_on_editor_script_changed)
	
	_on_editor_script_changed.call_deferred(null)

func _exit_tree() -> void:
	if editor_settings.settings_changed.is_connected(_on_editor_settings_settings_changed):
		editor_settings.settings_changed.disconnect(_on_editor_settings_settings_changed)
	
	editor_settings = null
	if script_editor.editor_script_changed.is_connected(_on_editor_script_changed):
		script_editor.editor_script_changed.disconnect(_on_editor_script_changed)
	
	script_editor = null
	script_editor_base = null
	if base_editor.lines_edited_from.is_connected(_on_lines_edited_from):
		base_editor.lines_edited_from.disconnect(_on_lines_edited_from)
	
	if base_editor.focus_exited.is_connected(_on_focus_exited):
		base_editor.focus_exited.disconnect(_on_focus_exited)
	
	base_editor = null
	method_icon = null
	lambda_icon = null

func _input(event: InputEvent) -> void:
	if main_screen_name != "Script":
		return
	
	if event is not InputEventKey:
		return
	
	if Input.is_key_pressed(KEY_CTRL):
		if Input.is_key_pressed(KEY_ALT):
			if event.is_released() and event.keycode == KEY_SPACE:
				GDScriptParser.init(indent_type, indent_size)
				var caret_line: int = base_editor.get_caret_line()
				var current_line: String = base_editor.get_line(caret_line)
				if GDScriptParser.is_comment(base_editor, caret_line):
					return
				
				if not GDScriptParser.parse_line(current_line):
					return
				
				if not GDScriptParser.has_connect():
					return
				
				if not GDScriptParser.caret_is_on_connect(base_editor):
					return
				
				if not GDScriptParser.find_object_type(script_editor, get_editor_interface()):
					return
				
				GDScriptParser.find_signal_args(script_editor)
				var method_text: String = GDScriptParser.get_method_text(current_line)
				var lambda_text: String = GDScriptParser.get_lambda_text(current_line)
				if GDScriptParser.split_size <= 1:
					return
				
				base_editor.add_code_completion_option(
					CodeEdit.KIND_PLAIN_TEXT,
					method_text.replace("pass", ""),
					GDScriptParser.callable_name,
					Color.WHITE,
					method_icon
				)
				base_editor.add_code_completion_option(
					CodeEdit.KIND_PLAIN_TEXT,
					lambda_text.replace("pass", ""),
					lambda_text,
					Color.WHITE,
					lambda_icon
				)
				base_editor.update_code_completion_options(true)
				GDScriptParser.clear()
				

func _on_main_screen_changed(screen_name: String) -> void:
	main_screen_name = screen_name

func _on_editor_settings_settings_changed() -> void:
	indent_type = editor_settings.get_setting("text_editor/behavior/indent/type")
	indent_size = editor_settings.get_setting("text_editor/behavior/indent/size")

func _on_editor_script_changed(script: Script) -> void:
	script_editor_base = script_editor.get_current_editor()
	if is_instance_valid(script_editor_base):
		base_editor = get_base_editor()
		if not base_editor.lines_edited_from.is_connected(_on_lines_edited_from):
			base_editor.lines_edited_from.connect(_on_lines_edited_from)
		
		if not base_editor.focus_exited.is_connected(_on_focus_exited):
			base_editor.focus_exited.connect(_on_focus_exited)

func _on_lines_edited_from(from_line: int, to_line: int) -> void:
	if from_line != to_line:
		return
	
	if GDScriptParser.is_comment(base_editor, to_line):
		base_editor.cancel_code_completion()
		return
	
	if GDScriptParser.signal_name.is_empty():
		return
	
	if GDScriptParser.inset_func_text.is_empty():
		return
	
	if not base_editor.get_line(to_line).contains(GDScriptParser.callable_name):
		return
	
	var line_count: int = base_editor.get_line_count() - 1
	script_editor.goto_line.call_deferred(line_count)
	base_editor.insert_line_at.call_deferred(line_count, GDScriptParser.inset_func_text)
	GDScriptParser.signal_name = ""
	GDScriptParser.callable_name = ""
	GDScriptParser.inset_func_text = ""

func _on_focus_exited() -> void:
	base_editor.cancel_code_completion()

func get_script_editor_container() -> TabContainer:
	return get_editor_interface().get_script_editor().get_child(0).get_child(1).get_child(1).get_child(0)

func get_base_editor() -> CodeEdit:
	return script_editor_base.get_base_editor()
