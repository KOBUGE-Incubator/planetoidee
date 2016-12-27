extends Control

export(float) var min_arrow_marker_distance = 400

var object_markers = {}

onready var markers = get_node("markers")

func _ready():
	set_process(true)

func _process(delta):
	var center = get_parent().get_screen_center()
	var rotation = get_parent().get_screen_rotation()
	var screen_size = get_parent().get_screen_size()
	markers.set_pos(get_rect().size/2)
	for landmark in get_tree().get_nodes_in_group("landmarks"):
		if !object_markers.has(landmark):
			object_markers[landmark] = preload("hud/marker_arrow.tscn").instance()
			markers.add_child(object_markers[landmark])
		
		if center.distance_squared_to(landmark.get_global_pos()) > min_arrow_marker_distance * min_arrow_marker_distance:
			var angle = (landmark.get_global_pos() - center).angle() + rotation
			object_markers[landmark].show()
			object_markers[landmark].set_pos(Vector2(0,1).rotated(angle) * screen_size / 2)
			object_markers[landmark].set_rot(angle + PI)
		else:
			object_markers[landmark].hide()
		
	for player in get_tree().get_nodes_in_group("player"):
		if !object_markers.has(player):
			object_markers[player] = preload("hud/marker_arrow.tscn").instance()
			markers.add_child(object_markers[player])
		
		var angle = player.get_linear_velocity().angle() + rotation
		object_markers[player].set_pos(Vector2(0,1).rotated(angle) * screen_size / 2)
		object_markers[player].set_rot(angle + PI)
