extends "marker_arrow.gd"

onready var angular = get_node("angular")
onready var initial_angular_scale = angular.get_scale()

export(float) var angular_log_scale = 5
export(float) var angular_size = 20

func _process(delta):
	set_orientation(target.get_linear_velocity().angle())
	var angular_velocity = target.get_angular_velocity()
	var radius = hud.screen_size.length()
	var marker_size = log(abs(angular_velocity) + 1) * angular_log_scale * sqrt(radius)
	var marker_angle = -PI / 2 * sign(angular_velocity) * (1 + asin(marker_size * angular_size / radius))
	angular.set_scale(initial_angular_scale * Vector2(1, marker_size))
	angular.set_rot(marker_angle)
