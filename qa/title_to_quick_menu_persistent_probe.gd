extends Node

const RUNNER_SCRIPT := preload("res://qa/title_to_quick_menu_persistent_runner.gd")

func _ready() -> void:
	var runner := Node.new()
	runner.set_script(RUNNER_SCRIPT)
	get_tree().root.call_deferred("add_child", runner)
	runner.call_deferred("run")
	queue_free()
