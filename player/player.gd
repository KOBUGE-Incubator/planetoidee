extends RigidBody2D


export(float) var camera_movement_scale = 0.1
export(float, EASE) var camera_movement_easing = 0.1

var camera_offset = Vector2()
var engines = {}

onready var camera = get_node("camera")

func _ready():
	for node in get_children():
		if node.has_method("should_fire"):
			engines[node] = true
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

func _integrate_forces(state):
	var transform = state.get_transform()
	for engine in engines:
		if engine.should_fire():
			engine.activate(1)
			var impulse = transform.basis_xform(Vector2(0, -1).rotated(engine.get_rot()))
			var origin = transform.basis_xform(engine.get_pos())
			apply_impulse(origin, impulse * engine.activation * engine.power * state.get_step())
		else:
			engine.activate(0)
	
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
