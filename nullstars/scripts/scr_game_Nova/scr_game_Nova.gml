// Feather ignore GM1051
#macro SETUP_OBJ_NOVA \
	fn_tick := obj_game_Nova_fn_tick; \
	fn_draw := obj_game_Nova_fn_draw; \
	priority := 1; \
	x_vel = 0; \
	y_vel = 0;

function obj_game_Nova_fn_tick() {
	var _kh := keyboard_check(ord("D")) - keyboard_check(ord("A"));
	var _kv := keyboard_check(ord("S")) - keyboard_check(ord("W"));
	
	x_vel = approach(x_vel, _kh * 4, 1);
	y_vel = approach(y_vel, _kv * 4, 1);
	
	obj_Body_move_x(x_vel);
	obj_Body_move_y(y_vel);
}

function obj_game_Nova_fn_draw() {
	draw_self();
}
