extends Node


const MULTITHREAD_ENABLED = "enable_multithreading"
const GENERATION_DELAY = "delay_before_generation"
const INLINE_VECTOR_FIELDS = "inline_vector_fields"
const GROUP_NODES_BY_TYPE = "group_nodes_by_type"
const AUTOSAVE_ENABLED = "enable_autosave"
const AUTOSAVE_INTERVAL = "autosave_interval"
const EDITOR_SCALE = "editor_scale"
const TOUCHPAD_NAVIGATION = "touchpad_navigation"

var _path = "user://config.json"
var _initialized := false
var _json = JSON.new()


# Default settings
var _settings = {
	MULTITHREAD_ENABLED: true,
	GENERATION_DELAY: 75,
	INLINE_VECTOR_FIELDS: false,
	GROUP_NODES_BY_TYPE: false,
	AUTOSAVE_ENABLED: true,
	AUTOSAVE_INTERVAL: 300,
	EDITOR_SCALE: 100,
	TOUCHPAD_NAVIGATION: false
}

var _require_restart := [
	EDITOR_SCALE
]


func _ready() -> void:
	load_or_create_config()


func has(setting: String) -> bool:
	return _settings.has(setting)


func get_setting(setting: String):
	if not _initialized:
		load_or_create_config()
	
	if _settings.has(setting):
		return _settings[setting]
	
	return null


func update_setting(setting: String, value) -> void:
	var old_value = _settings[setting]
	_settings[setting] = value
	save_config()
	GlobalEventBus.settings_updated.emit(setting)

	if _require_restart.has(setting): # Keep using the old value until the user restarts the application
		_settings[setting] = old_value


func load_or_create_config() -> void:
	var dir = Directory.new()
	dir.open("user://")
	if dir.file_exists(_path):
		print(_path, " already exists, loading config")
		load_config()
	else:
		print(_path, " doesn't exists, creating the config file")
		save_config()

	_initialized = true


func load_config() -> void:
	var file = File.new()
	file.open(_path, File.READ)
	if not _json.parse(file.get_as_text()):
		print("Failed to parse the configuration file ", _path)
		print(_json.get_error_message(), " l", _json.get_error_line())
		return

	# Don't override the whole settings dict at once in case the settings file doesn't contain 
	# all the settings entries. (Happens when we add new settings)
	var dict = _json.get_data()
	for key in dict:
		_settings[key] = dict[key]

	# Fix because of wrong defaults set on the 0.6 release
	if _settings[EDITOR_SCALE] < 75 or _settings[EDITOR_SCALE] > 400:
		_settings[EDITOR_SCALE] = 100


func save_config() -> void:
	var file = File.new()
	file.open(_path, File.WRITE)
	file.store_string(_json.stringify(_settings))
	file.close()
