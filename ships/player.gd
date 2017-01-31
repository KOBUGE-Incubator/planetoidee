extends "ship.gd"

enum InputState {
	ANY_A, ANY_B,
	HOLD_A, HOLD_B,
	TAP_A, TAP_B,
	ANY_A_MASK = 1<<ANY_A, ANY_B_MASK = 1<<ANY_B,
	HOLD_A_MASK = 1<<HOLD_A, HOLD_B_MASK = 1<<HOLD_B,
	TAP_A_MASK = 1<<TAP_A, TAP_B_MASK = 1<<TAP_B,
	NONE = 0
}

const BUTTONS = [
	{
		action = "btn_a",
		mask = ANY_A_MASK,
		tap_mask = TAP_A_MASK,
		hold_mask = HOLD_A_MASK
	}, {
		action = "btn_b",
		mask = ANY_B_MASK,
		tap_mask = TAP_B_MASK,
		hold_mask = HOLD_B_MASK
	}, {
		action = "ui_up",
		mask = ANY_A_MASK | ANY_B_MASK,
		tap_mask = TAP_A_MASK | TAP_B_MASK,
		hold_mask = HOLD_A_MASK | HOLD_B_MASK
	}
]

export(float) var camera_movement_scale = 0.1
export(float, EASE) var camera_movement_easing = 0.1
export(float) var max_tap_time = 0.1
export(float) var tap_timeout = 0.1

var camera_offset = Vector2()
var input_state = NONE
var button_states = []
var hold_time = []

onready var camera = get_node("camera")

func _ready():
	for i in range(BUTTONS.size()):
		hold_time.push_back(0)
		button_states.push_back(0)
	set_process(camera_movement_scale)
	set_process_input(true)

func _process(delta):
	camera.set_offset(camera_offset.rotated(get_global_rot()))
	for i in range(BUTTONS.size()):
		hold_time[i] += delta
		var button = BUTTONS[i]
		if button_states[i] & button.mask == button.mask and hold_time[i] >= max_tap_time:
			button_states[i] |= button.hold_mask
		elif !button_states[i] & button.mask == button.mask and hold_time[i] > tap_timeout:
			button_states[i] &= ~button.tap_mask
	
	recalculate_input_state()

func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		var center_offset = (event.pos - get_viewport_rect().size / 2)
		var length_normalized = (center_offset / get_viewport_rect().size).length() * 2 + 0.1
		center_offset *= ease(max(length_normalized, 1), camera_movement_easing)
		camera_offset = center_offset * camera_movement_scale
	for i in range(BUTTONS.size()):
		var button = BUTTONS[i]
		if !(Globals.get("shortcuts_enabled") or button.action.begins_with("btn")): continue
		if event.is_action_pressed(button.action):
			hold_time[i] = 0
			button_states[i] |= button.mask
		elif event.is_action_released(button.action):
			if hold_time[i] < max_tap_time:
				button_states[i] |= button.tap_mask
			hold_time[i] = 0
			button_states[i] &= ~button.hold_mask
			button_states[i] &= ~button.mask

func recalculate_input_state():
	input_state = 0
	for state in button_states: input_state |= state
#	var s = ""
#	for i in range(8):
#		s += "1" if (input_state & (1<<i)) else "0"
#	print(s)

func hit():
	.hit()
	print(hits)

func should_trust(engine):
	return engine.input & input_state == engine.input

func should_fire(weapon):
	return weapon.input & input_state == weapon.input
