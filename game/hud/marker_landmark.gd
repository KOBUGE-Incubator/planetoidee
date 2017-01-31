extends "marker_arrow.gd"

export(float) var min_distance = 3000
export(Color) var ally_color = Color(0, 1, 0)
export(Color) var enemy_color = Color(1, 0, 0)
export(Color) var neutral_color = Color(1, 1, 1)

onready var sprite = get_node("sprite")

func _process(delta):
	var distance_squared = hud.screen_center.distance_squared_to(target.get_global_pos()) 
	if distance_squared > min_distance * min_distance:
		set_orientation((target.get_global_pos() - hud.screen_center).angle())
		show()
	else:
		hide()
	
	var max_highlight = 0
	if target.is_in_group("enemy"):
		max_highlight = 0.9
		sprite.set_modulate(enemy_color)
	elif target.is_in_group("ally"):
		max_highlight = 0.4
		sprite.set_modulate(ally_color)
	else:
		sprite.set_modulate(neutral_color)
	
	if hud.track_marker != self:
		var dot = UP.rotated(get_rot()).dot(TARGET)
		var precision = 1 - 0.7 / pow(distance_squared, 0.5*0.99)
		if dot > precision:
			var attained = (dot - precision) / (1 - precision)
			aura.show()
			aura.set_modulate(sprite.get_modulate())
			aura.set_opacity(attained * attained * max_highlight)
		else:
			aura.hide()
