extends Control

const MARKERS = {
	landmarks = {
		group = "landmarks",
		scene = preload("hud/marker_landmark.tscn")
	},
	velocity = {
		group = "player",
		scene = preload("hud/marker_velocity.tscn"),
		track = false
	},
	track = {
		group = "player",
		scene = preload("hud/marker_track.tscn"),
		track = false
	}
}

var object_markers = {}
var track_marker = null
var track_marker_i = 0
var track_target_markers = [null]

onready var markers = get_node("markers")
onready var up_marker = get_node("up_marker")

var screen_center = Vector2()
var screen_rotation = 0
var screen_size = Vector2()

func _ready():
	for name in MARKERS:
		object_markers[name] = {}
	
	set_process(true)
	set_process_input(true)

func _input(event):
	if track_target_markers.size() != 0 and !event.is_echo() and event.is_pressed() and Globals.get("shortcuts_enabled"):
		var change = event.is_action("ui_focus_next") - event.is_action("ui_focus_prev")
		
		if change != 0:
			if track_marker:
				track_marker.activate(0)
			
			var original_i = track_marker_i
			var first = true
			while first or (track_marker and !track_marker.is_activatable() and track_marker_i != original_i):
				first = false
				track_marker_i = (track_marker_i + change + track_target_markers.size()) % track_target_markers.size()
				track_marker = track_target_markers[track_marker_i]
			
			if track_marker:
				track_marker.activate(1)

func _process(delta):
	screen_center = get_parent().get_screen_center()
	screen_rotation = get_parent().get_screen_rotation()
	screen_size = get_parent().get_screen_size()
	markers.set_pos(get_rect().size/2)
	up_marker.set_pos(get_rect().size/2 * Vector2(1,0))
	for name in MARKERS:
		var marker_group = MARKERS[name].group
		var marker_scene = MARKERS[name].scene
		var marker_track = !MARKERS[name].has("track") or MARKERS[name].track
		
		for node in get_tree().get_nodes_in_group(marker_group):
			if !object_markers[name].has(node):
				var new_marker = marker_scene.instance()
				new_marker.set_target(node)
				new_marker.set_hud(self)
				node.connect("exit_tree", self, "remove_marker", [node])
				markers.add_child(new_marker)
				object_markers[name][node] = new_marker
				
				if marker_track:
					track_target_markers.push_back(new_marker)

func remove_marker(node):
	if !is_inside_tree(): return
	for name in MARKERS:
		if object_markers[name].has(node):
			track_target_markers.erase(object_markers[name][node])
			if track_marker == object_markers[name][node]:
				track_marker = null
			object_markers[name][node].queue_free()
			if object_markers[name].has(node):
				object_markers[name][node] = null
	
	var win = get_tree().get_nodes_in_group("enemy").size() == 0
	var loss = get_tree().get_nodes_in_group("ally").size() == 0
	if win and loss:
		get_node("end_game").show()
		get_node("end_game").set_text("Ah, it's actually a tie (click to retry)!")
	elif win:
		get_node("end_game").show()
		get_node("end_game").set_text("Your team won!")
	elif loss:
		get_node("end_game").show()
		get_node("end_game").set_text("Your team lost (click to retry)!")


func restart():
	get_tree().change_scene(get_tree().get_current_scene().get_filename())
