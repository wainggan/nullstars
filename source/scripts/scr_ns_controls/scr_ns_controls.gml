#macro ns_control_LEFT "left"
#macro ns_control_RIGHT "right"
#macro ns_control_DOWN "down"
#macro ns_control_UP "up"
#macro ns_control_JUMP "jump"
#macro ns_control_DASH "dash"
#macro ns_control_GRAB "grab"
#macro ns_control_MENU "menu"

function ns_control() {
	return ns_root().control.manager;
}

function ns_control_hold(_name) {
	return ns_control().check(_name);
}

function ns_control_press(_name, _buffer = undefined) {
	return ns_control().check_pressed(_name, _buffer);
}

function ns_control_release(_name, _buffer = undefined) {
	return ns_control().check_released(_name, _buffer);
}

function ns_Control() constructor {
	manager := new vinput_Manager(0, 0.2);
	
	manager.create_input("horizontal")
		.add_keyboard_axis(vk_left, vk_right)
		.add_keyboard_axis(ord("A"), ord("D"))
		.add_gamepad_stick(gp_axislh);
	
	manager.create_input("vertical")
		.add_keyboard_axis(vk_up, vk_down)
		.add_keyboard_axis(ord("W"), ord("S"))
		.add_gamepad_stick(gp_axislv);
	
	manager.create_input(ns_control_LEFT)
		.add_keyboard_key(vk_left)
		.add_keyboard_key(ord("A"))
		.add_gamepad_stick_virtual(gp_axislh, -1)
		.add_gamepad_button(gp_padl);
	
	manager.create_input(ns_control_RIGHT)
		.add_keyboard_key(vk_right)
		.add_keyboard_key(ord("D"))
		.add_gamepad_stick_virtual(gp_axislh, 1)
		.add_gamepad_button(gp_padr);
	
	manager.create_input(ns_control_UP)
		.add_keyboard_key(vk_up)
		.add_keyboard_key(ord("W"))
		.add_gamepad_stick_virtual(gp_axislv, -1, 0.2)
		.add_gamepad_button(gp_padu);
	
	manager.create_input(ns_control_DOWN)
		.add_keyboard_key(vk_down)
		.add_keyboard_key(ord("S"))
		.add_gamepad_stick_virtual(gp_axislv, 1, 0.2)
		.add_gamepad_button(gp_padd);
	
	manager.create_input(ns_control_JUMP)
		.add_keyboard_key(ord("Z"))
		.add_keyboard_key(ord("C"))
		.add_keyboard_key(ord("J"))
		.add_keyboard_key(ord("L"))
		.add_gamepad_button(gp_face1)
		.add_gamepad_button(gp_face4)
	
	manager.create_input(ns_control_DASH)
		.add_keyboard_key(ord("X"))
		.add_keyboard_key(ord("K"))
		.add_gamepad_button(gp_face2)
		.add_gamepad_button(gp_face3);
	
	manager.create_input(ns_control_GRAB)
		.add_keyboard_key(vk_shift)
		.add_keyboard_key(vk_space)
		.add_gamepad_shoulder_virtual(gp_shoulderl)
		.add_gamepad_shoulder_virtual(gp_shoulderr);
	
	manager.create_input(ns_control_MENU)
		.add_keyboard_key(vk_escape)
		.add_keyboard_key(vk_control)
		.add_keyboard_key(ord("V"))
		.add_keyboard_key(ord("E"))
		.add_keyboard_key(vk_tab)
		.add_gamepad_shoulder_virtual(gp_start);
	
	static update := function () {
		manager.update();
	};
	
	LOG(Log.Note, "Controls(): initialized");
}
