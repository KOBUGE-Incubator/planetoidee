extends "ship.gd"

export(float) var rotatation_speed = 4
export(float) var shot_speed = 5000
export(float) var max_distnace = 30000
export(float) var uncertainty = 0.1
export(String) var target_group = "ally"

func _ready():
	if target_group != "enemy":
		add_to_group("enemy")
	else:
		add_to_group("ally")

func should_trust(engine):
	return true # It's a turret, but say the engines are there for a reason

func should_fire(weapon):
	var direction = Vector2(0, 1).rotated(weapon.get_global_rot())
	var vantage = get_global_pos()
	var space = get_world_2d().get_direct_space_state()
	
	for player in get_tree().get_nodes_in_group(target_group):
		var time_estimate = player.get_global_pos().distance_to(vantage) / shot_speed * uncertainty
		var target = player.get_global_pos() + player.get_linear_velocity() * time_estimate
		var distance = vantage.distance_to(target)
		if distance < max_distnace and (target - vantage).normalized().dot(direction) > 1 - 0.7 / distance:
			if space.intersect_ray(vantage, direction * distance, [self, player], 1, space.TYPE_MASK_COLLISION).empty():
				return true
	return false

func _integrate_forces(state):
	._integrate_forces(state)
	var vantage = get_global_pos()
	
	var min_distance_squared = 0
	var min_target = null
	for player in get_tree().get_nodes_in_group(target_group):
		var time_estimate = player.get_global_pos().distance_to(vantage) / shot_speed * uncertainty
		var target = player.get_global_pos() + player.get_linear_velocity() * time_estimate
		var distance_squared = target.distance_squared_to(vantage)
		
		if min_target == null or distance_squared < min_distance_squared and distance_squared < max_distnace * max_distnace:
			min_distance_squared = distance_squared
			min_target = target
	
	if min_target != null:
		var direction = (min_target - vantage).normalized()
		var current_direction = Vector2(0, 1).rotated(state.get_transform().get_rotation())
		
		state.set_angular_velocity(current_direction.angle_to(direction) * state.get_step() * rotatation_speed + state.get_angular_velocity())
