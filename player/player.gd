extends RigidBody2D


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _integrate_forces(state):
	var impulse = Vector2()
	
	if Input.is_action_pressed("ui_left"):
		impulse.x -= 1
	if Input.is_action_pressed("ui_right"):
		impulse.x += 1
	if Input.is_action_pressed("ui_up"):
		impulse.y -= 1
	if Input.is_action_pressed("ui_down"):
		impulse.y += 1
	
	state.set_linear_velocity(impulse * state.get_step() * 1000 + state.get_linear_velocity())