extends "marker_arrow.gd"

export(float) var min_distance = 3000
export(Color) var ally_color = Color(0, 1, 0)
export(Color) var enemy_color = Color(1, 0, 0)
export(Color) var neutral_color = Color(1, 1, 1)

func _process(delta):
	var distance_squared = hud.screen_center.distance_squared_to(target.get_global_pos()) 
	if distance_squared > min_distance * min_distance:
		set_orientation((target.get_global_pos() - hud.screen_center).angle())
		show()
	else:
		hide()
	
	if target.is_in_group("enemy"):
		get_node("sprite").set_modulate(enemy_color)
	elif target.is_in_group("ally"):
		get_node("sprite").set_modulate(ally_color)
	else:
		get_node("sprite").set_modulate(neutral_color)
