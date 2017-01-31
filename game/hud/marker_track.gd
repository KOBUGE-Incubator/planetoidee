extends "marker_arrow.gd"

export(float) var assumed_speed = 400
export(float) var min_distance = 30

func _process(delta):
	aura.hide()
	if hud.track_marker and hud.track_marker extends preload("marker_landmark.gd"):
		var target_pos = hud.track_marker.target.get_global_pos()
		
		var time_estimate = hud.screen_center.distance_to(target_pos) / assumed_speed
		var linear_damp = target.get_linear_damp() if target.get_linear_damp() > 0 else 0.1
		var angular_damp = target.get_angular_damp() if target.get_angular_damp() > 0 else 1
		var velocity_offset = target.get_linear_velocity() * pow(time_estimate, 1 - linear_damp)
		
		var track_position = target_pos - velocity_offset
		var distance_squared = hud.screen_center.distance_squared_to(track_position) 
		
		if distance_squared > min_distance * min_distance:
			var angle = (track_position - hud.screen_center).angle()
#			angle += target.get_angular_velocity() * pow(angular_damp, time_estimate)
			set_orientation(angle)
			show()
		else:
			hide()
	else:
		hide()
	var dot = UP.rotated(get_rot()).dot(TARGET)
	if dot > 0.99:
		aura.show()
		aura.set_opacity((dot - 0.99) / 0.01)
