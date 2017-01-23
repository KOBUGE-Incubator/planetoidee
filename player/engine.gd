extends Node2D

export(float) var power = 200
export(float) var transition_time = 0.2
export(String) var action = "ui_up"
export(float) var activation = 0 setget set_activation
export(float) var patricle_exaust_speed = 200

onready var sprite_on = get_node("sprite/sprite_on")
onready var particles = get_node("particles")
onready var tween = get_node("tween")

onready var base_lifetime = particles.get_lifetime()
onready var base_spread = particles.get_param(Particles2D.PARAM_SPREAD)
onready var action_parts = action.split("+")

var target_activation = 0

func _ready():
	set_process(true)
	set_activation(activation) # Update

func _process(delta):
	# IRL, particles should get your velocity too
	var velocity = get_parent().get_linear_velocity() * 0.9
	velocity += get_global_transform().basis_xform(Vector2(0, patricle_exaust_speed) * activation)
	var length = velocity.length()
	particles.set_param(Particles2D.PARAM_LINEAR_VELOCITY, length)
	particles.set_param(Particles2D.PARAM_DIRECTION, fmod(rad2deg(velocity.angle() - get_global_rot() + 2 * PI), 360))
	particles.set_param(Particles2D.PARAM_SPREAD, base_spread / (length + 1))

func should_fire():
	for part in action_parts:
		if !Input.is_action_pressed(part):
			return false
	return true

func set_activation(amount):
	if sprite_on and particles:
		sprite_on.set_opacity(amount * amount)
#		particles.set_opacity(amount)
		particles.set_emitting(amount > 0.1)
	activation = amount

func activate(amount = 1.0):
	if target_activation != amount:
		target_activation = amount
		tween.remove_all()
		tween.interpolate_property(self, "activation", activation, amount, transition_time, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		tween.start()
