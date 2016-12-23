tool
extends Control

export(FloatArray) var splits = [] setget set_splits
export(float) var size_scale = 1 setget set_size_scale
export(float) var pattern_param = 1 setget set_pattern_param
export(float) var pattern_offset = 10 setget set_pattern_offset
export(float) var transition_distance = 0.5 setget set_transition_distance
export(bool) var filter = false
export(bool) var mipmap = false
var viewports = []
onready var root_viewport = get_node("viewport")
onready var backgrounds = get_node("viewport/backgrounds")
var frame_i = 0

func _ready():
	randomize()
	regen_viewports()
	remake_shader()
	if !get_tree().is_editor_hint():
		set_process(true)
		set_process_input(true)
		set_process_unhandled_input(true)

func _input(event):
	root_viewport.input(event)
func _unhandled_input(event):
	root_viewport.unhandled_input(event)

func _process(delta):
	frame_i += 1
	var offset = root_viewport.get_rect().size / 2
	var transform = root_viewport.get_canvas_transform()
	transform = transform.translated(transform.basis_xform_inv(-offset))
	var base_transform = Matrix32().translated(offset)
	var low_performance = 1 / delta < 50
	for i in range(viewports.size()):
		var split_transform = base_transform * transform.scaled(Vector2(1, 1) / splits[i])
		viewports[i].set_canvas_transform(split_transform)
		if low_performance:
			if i == 0 or frame_i % i:
				viewports[i].set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_ONCE)
		else:
			viewports[i].set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_ALWAYS)
	get_material().set_shader_param("pattern_scale", offset / (offset - Vector2(pattern_offset, pattern_offset)))
	var background_size = splits[splits.size() - 1] * root_viewport.get_rect().size
	var center = get_screen_center()
	for background_layer in backgrounds.get_children():
		background_layer.update_details(center, background_size)

func set_splits(new_splits):
	splits = new_splits
	if is_inside_tree():
		regen_viewports()
		remake_shader()
func set_size_scale(new_scale):
	size_scale = new_scale
	if is_inside_tree():
		regen_viewports()
		update_uniforms()
func set_pattern_param(new_param):
	pattern_param = new_param
	if is_inside_tree():
		update_uniforms()
func set_pattern_offset(new_offset):
	pattern_offset = new_offset
	if is_inside_tree():
		update_uniforms()
func set_transition_distance(new_distance):
	transition_distance = new_distance
	if is_inside_tree():
		remake_shader()

func get_screen_center():
	var rotated_center = - root_viewport.get_canvas_transform().get_origin() + root_viewport.get_rect().size / 2
	return root_viewport.get_canvas_transform().basis_xform_inv(rotated_center)

func get_screen_rotation():
	return root_viewport.get_canvas_transform().get_rotation()

func regen_viewports():
	if !is_inside_tree() or get_tree().is_editor_hint():
		return
	var world = root_viewport.get_world_2d()
	var size = get_viewport_rect().size * size_scale
	for viewport in viewports:
		viewport.queue_free()
	viewports = []
	for split in splits:
		var split_viewport = Viewport.new()
		split_viewport.set_use_own_world(false)
		split_viewport.set_world_2d(world)
		split_viewport.set_as_render_target(true)
		split_viewport.set_render_target_filter(filter)
		split_viewport.set_render_target_gen_mipmaps(mipmap)
		split_viewport.set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_ALWAYS)
		split_viewport.set_rect(Rect2(Vector2(), size))
		root_viewport.add_child(split_viewport)
		viewports.push_back(split_viewport)

func update_uniforms():
	var debug = !is_inside_tree() or get_tree().is_editor_hint()
	
	if !debug:
		assert(viewports.size() == splits.size())
		for i in range(splits.size()):
			var texture = viewports[i].get_render_target_texture()
			get_material().set_shader_param(get_shader_split_texture_name(i), texture)
	get_material().set_shader_param("pattern_param", pattern_param)

func remake_shader():
	var debug = !is_inside_tree() or get_tree().is_editor_hint()
	
	var shader = CanvasItemShader.new()
	var material = CanvasItemMaterial.new()
	shader.set_code("", shader_codegen_fragment(debug), "", 0, 0)
	material.set_shader(shader)
	set_material(material)
	update_uniforms()

func shader_repeat_replace(repeated_template):
	var shader_code = ""
	for i in range(splits.size()):
		var repeated = repeated_template
		repeated = repeated.replace("[split_distance]", splits[i])
		if i > 1:
			repeated = repeated.replace("[transition_split_distance]", (splits[i - 1] - splits[i - 2]) * transition_distance)
		elif i == 1:
			repeated = repeated.replace("[transition_split_distance]", splits[i - 1] * transition_distance)
		else:
			repeated = repeated.replace("[transition_split_distance]", 0)
		if i > 0:
			repeated = repeated.replace("[last_split_distance]", splits[i - 1])
		else:
			repeated = repeated.replace("[last_split_distance]", 0)
		
		
		repeated = repeated.replace("[split_texture_name]", get_shader_split_texture_name(i))
		repeated = repeated.replace("[debug_split_color]", "vec4(%f, %f, %f, 1)" % [(i + 1) & 1, (i + 1) & 2, (i + 1) & 4])
		shader_code += repeated
	return shader_code

func get_shader_split_texture_name(i):
	return "split_%s" % i

func shader_codegen_fragment(debug):
	var shader_code = ""
	
	if !debug:
		shader_code += shader_repeat_replace("""
			uniform texture [split_texture_name];
		""")
	
	shader_code += ("""
		uniform float pattern_param = 1;
		uniform vec2 pattern_scale = vec2(1,1);
		
		vec2 uvm = (UV * 2 - vec2(1,1)) * pattern_scale;
		
		float l = length(uvm);
		//float l = max(abs(uvm.x), abs(uvm.y));
		vec2 uvt = uvm * abs(1 / (l + 1) + 1 / (l - 1)) * pattern_param / l;
		//vec2 uvt = uvm * abs(tan(l * 3.141593 / 2) * pattern_param) / l;
		//vec2 uvt = uvm * l / (1.6 - abs(asin(l))) * pattern_param / l;
		float split_distance = max(abs(uvt.x), abs(uvt.y));
		bool unset_color = true;
		
		if(l > 1) {
			COLOR = vec4(0,0,0,0);
			unset_color = false;
		}
	""")
	
	if debug:
		shader_code += shader_repeat_replace("""
			if(unset_color && split_distance <= [split_distance]) {
				COLOR = [debug_split_color];
				unset_color = false;
			}
			if(l < 1 && split_distance > [last_split_distance] - [transition_split_distance] && split_distance <= [last_split_distance]) {
				COLOR = mix(COLOR, [debug_split_color], 
					(split_distance - [last_split_distance] + [transition_split_distance]) / [transition_split_distance]);
				//COLOR = vec4(1,1,1,1);
				//COLOR.a = (split_distance - [last_split_distance] + [transition_split_distance]) / [transition_split_distance];
			}
		""")
	else:
		shader_code += shader_repeat_replace("""
			if(unset_color && split_distance <= [split_distance]) {
				COLOR = tex([split_texture_name], uvt / [split_distance] / 2 + vec2(.5,.5));
				unset_color = false;
			}
			if(l < 1 && split_distance > [last_split_distance] - [transition_split_distance] && split_distance <= [last_split_distance]) {
				COLOR = mix(COLOR, tex([split_texture_name], uvt / [split_distance] / 2 + vec2(.5,.5)), 
					(split_distance - [last_split_distance] + [transition_split_distance]) / ([transition_split_distance]));
			}
		""")
	shader_code += ("""
		if(unset_color) {
			COLOR = vec4(0,0,0,0);
		}
		//COLOR = mix(COLOR, vec4(0,0,0,1), fract(split_distance * 2));
	""")
	
	return shader_code
