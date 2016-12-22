extends RigidBody2D

export(float) var engine_power = 200
export(float) var camera_movement_scale = 0.1
export(float, EASE) var camera_movement_easing = 0.1

var actions = [
	"btn_a",
	"btn_b"
]
var camera_offset = Vector2()

onready var engines = [
	get_node("engine_a"),
	get_node("engine_b")
]

onready var camera = get_node("camera")

func _ready():
	set_process(camera_movement_scale)
	set_process_input(true)

func _draw():
	for i in range(actions.size()):
		if Input.is_action_pressed(actions[i]):
			var impulse = Vector2(0, 1).rotated(engines[i].get_rot())
			var origin = engines[i].get_pos()
			draw_line(origin, origin - impulse * engine_power, Color(1,0,0))

func _process(delta):
	camera.set_offset(camera_offset.rotated(get_global_rot()))

func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		var center_offset = (event.pos - get_viewport_rect().size / 2)
		var length_normalized = (center_offset / get_viewport_rect().size).length() * 2 + 0.1
		center_offset *= ease(max(length_normalized, 1), camera_movement_easing)
		camera_offset = center_offset * camera_movement_scale

func _integrate_forces(state):
	update()
	for i in range(actions.size()):
		if Input.is_action_pressed(actions[i]):
			var impulse = Vector2(0, 1).rotated(engines[i].get_rot())
			impulse = state.get_transform().basis_xform(impulse)
			var origin = state.get_transform().basis_xform(engines[i].get_pos())
			apply_impulse(origin, impulse * engine_power * state.get_step())
	
	if Input.is_action_pressed("ui_cancel"): # Debug
		var impulse = Vector2()
		
		if Input.is_action_pressed("ui_left"):
			impulse.x -= 1
		if Input.is_action_pressed("ui_right"):
			impulse.x += 1
		if Input.is_action_pressed("ui_up"):
			impulse.y -= 1
		if Input.is_action_pressed("ui_down"):
			impulse.y += 1
		
		impulse = state.get_transform().basis_xform(impulse)
		
		state.set_linear_velocity(impulse * state.get_step() * 1000 + state.get_linear_velocity())
