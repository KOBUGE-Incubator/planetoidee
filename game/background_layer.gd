extends TextureFrame

export(Vector2) var movement_scale = Vector2(1,1)
onready var texture_size = get_texture().get_size()

func update_details(screen_offset, size):
	var offset = screen_offset * movement_scale
	offset.x = fmod(offset.x, texture_size.x)
	offset.y = fmod(offset.y, texture_size.y)
	var start = (screen_offset - size).snapped(texture_size) + offset
	var end = (screen_offset + size).snapped(texture_size) + offset
	set_pos(start)
	set_size(end - start)
