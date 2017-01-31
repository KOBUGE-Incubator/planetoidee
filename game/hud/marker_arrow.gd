extends Node2D

const UP = Vector2(0, 1)
const TARGET = Vector2(0, 1)

var target
var hud
var aura

func _ready():
	if !aura:
		aura = get_node("sprite").duplicate()
		aura.set_scale(Vector2(1.05, 1.05))
		aura.set_opacity(0.3)
		aura.hide()
		add_child(aura)
	set_process(true)

func set_target(_target):
	target = _target

func target_exited():
	queue_free()

func activate(on):
	aura.set_hidden(!on)

func is_activatable():
	return is_visible()

func set_hud(_hud):
	hud = _hud

func set_orientation(angle):
	angle += hud.screen_rotation
	set_pos(Vector2(0,1).rotated(angle) * hud.screen_size / 2)
	set_rot(angle + PI)
