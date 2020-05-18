tool
extends ConceptNode

"""
This node allows the user to save the input as a .tscn file by using ResourceSaver
"""

var last_export_path := ""
var last_export = null
var directory := Directory.new()

func _init() -> void:
	unique_id = "save_tscn_output"
	display_name = "Save Output"
	category = "Output"
	description = "Saves the output as a tscn file"

	set_input(0, "Path", ConceptGraphDataType.STRING)
	set_input(1, "Node", ConceptGraphDataType.NODE_3D)


func _fix_path(path:String):
	if not path.begins_with("res://"):
		path = "res://" + path
	if not path.ends_with(".tscn"):
		path += ".tscn"
	return path


func _save_scene(scene, path:String):
	var packed_scene := PackedScene.new()
	if packed_scene.pack(scene) != OK:
		print("Failed to pack resource")
		return

	if last_export == null and last_export_path == "" and directory.file_exists(path):
		# consider that the file in path is an old packaged scene
		# FIXME: this has a bug: if the user puts a path where there is a file already,
		# FIXME: and then restarts godot, this node will consider that file as ours on startup, and will overwrite it.
		last_export_path = path
		return
	elif directory.file_exists(path):
		# should not overwrite existing file in path
		return
	elif last_export != null and last_export._get_bundled_scene().hash() == packed_scene._get_bundled_scene().hash():
		# just move the existing file
		if directory.rename(last_export_path, path) != OK:
			print("Failed to move file")
			return
		last_export_path = path
		last_export = packed_scene
	else:
		# actually build and save the file
		_remove_scene(last_export_path)
		ResourceSaver.save(path, packed_scene)
		last_export_path = path
		last_export = packed_scene


func _remove_scene(path:String):
	if path != "" and directory.file_exists(path):
		directory.remove(path)


func _generate_outputs() -> void:
	var path: String = get_input_single(0, "")
	var out = get_input_single(1)

	if path and path != "" and out:
		path = _fix_path(path)
		_save_scene(out, path)
	elif last_export_path != "":
		_remove_scene(last_export_path)
		last_export_path = ""


func reset() -> void:
	.reset()
	emit_signal("node_changed", self, true)
