extends RigidBody2D

export(float) var health = 100
#export(float) 
var damage_velocity_change = 4000
var velocity_change_damage_multiplier = 0.005

onready var animation_player = get_node("animation_player")

var last_velocity = Vector2()
var engines = {}
var weapons = {}
var hits = 0

func _ready():
	for node in get_children():
		if node.has_method("trust"):
			engines[node] = true
	
	for node in get_children():
		if node.has_method("fire"):
			weapons[node] = true

func damage(amount, by = null):
	if health <= 0: return
	health -= amount
	if by and by.has_method("hit"):
		by.hit()
	if health <= 0:
		die()

func hit():
	hits += 1

func die():
	for engine in engines:
		engine.trust(0)
#	set_collision_mask(0)
#	set_layer_mask(0)
	if is_in_group("ally"):
		remove_from_group("ally")
	elif is_in_group("enemy"):
		remove_from_group("enemy")
	if animation_player:
		animation_player.play("die")
		animation_player.connect("finished", self, "queue_free")
	else:
		call_deferred("queue_free")

func should_trust(engine):
	return false

func should_fire(weapon):
	return false

func _integrate_forces(state):
	if health <= 0: return
	var transform = state.get_transform()
	for engine in engines:
		if should_trust(engine):
			engine.trust(1)
			var impulse = transform.basis_xform(Vector2(0, -1).rotated(engine.get_rot()))
			var origin = transform.basis_xform(engine.get_pos())
			apply_impulse(origin, impulse * engine.power * state.get_step())
		else:
			engine.trust(0)

	for weapon in weapons:
		if should_fire(weapon):
			weapon.fire(self)
	
	var velocity_change_magnitude = state.get_linear_velocity().distance_to(last_velocity) / state.get_step()
	if velocity_change_magnitude > damage_velocity_change:
		damage((velocity_change_magnitude - damage_velocity_change) * velocity_change_damage_multiplier)
	last_velocity = state.get_linear_velocity()
