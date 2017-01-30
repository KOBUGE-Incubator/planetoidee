extends Node2D

export(PackedScene) var scene
export(String) var action = "ui_up"
export(float) var cooldown = 0.5

onready var point = get_node("point")
onready var animation_player = get_node("animation_player")
onready var action_parts = action.split("+")

var cooldown_left = 0

func _ready():
	set_process(true)

func _process(delta):
	cooldown_left -= delta

func input():
	for part in action_parts:
		if !Input.is_action_pressed(part):
			return false
	return true

func fire():
	if cooldown_left < 0:
		cooldown_left = cooldown
		animation_player.play("shoot")
		var shot = scene.instance()
		var parent = get_viewport().get_child(get_viewport().get_child_count() - 1)
		parent.add_child(shot)
		
		shot.set_global_transform(point.get_global_transform())
