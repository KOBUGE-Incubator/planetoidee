extends Node2D

export(PackedScene) var scene
export(int, FLAGS, "A", "B", "A hold", "B hold", "A tap", "B tap") var input = 0
export(float) var cooldown = 0.5

onready var point = get_node("point")
onready var animation_player = get_node("animation_player")

var cooldown_left = 0

func _ready():
	set_process(true)

func _process(delta):
	cooldown_left -= delta

func fire(by):
	if cooldown_left < 0:
		cooldown_left = cooldown
		animation_player.play("shoot")
		var shot = scene.instance()
		var parent = get_viewport().get_child(get_viewport().get_child_count() - 1)
		parent.add_child(shot)
		
		shot.originator = weakref(by)
		shot.set_global_transform(point.get_global_transform())
