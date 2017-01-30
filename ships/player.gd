extends "ship.gd"

export(float) var camera_movement_scale = 0.1
export(float, EASE) var camera_movement_easing = 0.1

var camera_offset = Vector2()

onready var camera = get_node("camera")

func _ready():
	set_process(camera_movement_scale)
	set_process_input(true)

func _process(delta):
	camera.set_offset(camera_offset.rotated(get_global_rot()))


func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		var center_offset = (event.pos - get_viewport_rect().size / 2)
		var length_normalized = (center_offset / get_viewport_rect().size).length() * 2 + 0.1
		center_offset *= ease(max(length_normalized, 1), camera_movement_easing)
		camera_offset = center_offset * camera_movement_scale

func should_trust(engine):
	return engine.input()

func should_fire(weapon):
	return weapon.input()
