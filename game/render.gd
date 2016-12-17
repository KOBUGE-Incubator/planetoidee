tool
extends Control

export(FloatArray) var splits setget regen_shader_and_viewports
export(float) var size_scale = 1
export(float) var pattern_scale = 1
export(bool) var filter = false
export(bool) var mipmap = false
var viewports = []
onready var root_viewport = get_node("viewport")

func _ready():
	regen_shader_and_viewports(splits)
	if !get_tree().is_editor_hint():
		set_process(true)

func _process(delta):
	var transform = root_viewport.get_canvas_transform()
	var offset = get_viewport_rect().size * size_scale / 2 / transform.get_scale()
	for i in range(viewports.size()):
		var split_transform = transform.scaled(Vector2(1, 1) / splits[i]).translated(offset * (splits[i] - 1 / size_scale))
		viewports[i].set_canvas_transform(split_transform)

func regen_shader_and_viewports(_splits):
	splits = _splits
	regen_viewports()
	regen_shader()

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

func regen_shader():
	var debug = !is_inside_tree() or get_tree().is_editor_hint()
	
	var shader = CanvasItemShader.new()
	var material = CanvasItemMaterial.new()
	shader.set_code("", shader_codegen_fragment(debug), "", 0, 0)
	material.set_shader(shader)
	
	if !debug:
		assert(viewports.size() == splits.size())
		for i in range(splits.size()):
			var texture = viewports[i].get_render_target_texture()
			material.set_shader_param(get_shader_split_texture_name(i), texture)
	material.set_shader_param("pattern_scale", pattern_scale)
	
	set_material(material)

func shader_repeat_replace(repeated_template):
	var shader_code = ""
	for i in range(splits.size()):
		var repeated = repeated_template
		repeated = repeated.replace("[split_distance]", splits[i])
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
		uniform float pattern_scale = 1;
		
		vec2 uvm = UV * 2 - vec2(1,1);
		
		float l = length(uvm);
		vec2 uvt = uvm * abs(1 / (l + pattern_scale) + 1 / (l - pattern_scale)) / l;
		float split_distance = max(abs(uvt.x), abs(uvt.y));
		bool unset_color = true;
		
		if(length(uvm) > pattern_scale) {
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
		""")
	else:
		shader_code += shader_repeat_replace("""
			if(unset_color && split_distance <= [split_distance]) {
				COLOR = tex([split_texture_name], uvt / [split_distance] / 2 + vec2(.5,.5));
				unset_color = false;
			}
		""")
	shader_code += ("""
		if(unset_color) {
			COLOR = vec4(0,0,0,0);
		}
	""")
	
	return shader_code
