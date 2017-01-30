extends Node2D

export(float) var speed = 3000
export(float) var max_distnace = 30000
export(float) var damage = 100

onready var raycast = get_node("raycast")

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	var direction = Vector2(0, 1).rotated(get_global_rot())
	
	max_distnace -= speed * delta
	set_pos(get_pos() + direction * speed * delta)
	
	if raycast.is_colliding():
		if raycast.get_collider() and raycast.get_collider().has_method("damage"):
			raycast.get_collider().damage(damage)
		max_distnace = 0
	
	if max_distnace <= 0:
		raycast.queue_free()
		get_node("animation_player").play("vanish")
		get_node("animation_player").connect("finished", self, "queue_free")
		set_fixed_process(false)
		set_script(null)
