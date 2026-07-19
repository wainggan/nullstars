// Feather ignore GM1051
#macro SETUP_OBJ_NOVA \
	fn_tick := obj_game_Nova_fn_tick; \
	fn_draw := obj_game_Nova_fn_draw; \
	x_vel = 0; \
	y_vel = 0;

function obj_game_Nova_fn_tick() {
	var _kh := keyboard_check(ord("D")) - keyboard_check(ord("A"))
	var _kv := keyboard_check(ord("S")) - keyboard_check(ord("W"))
	obj_Body_move_x(_kh * 4);
	obj_Body_move_y(_kv * 4);
}

function obj_game_Nova_fn_draw() {
	draw_self();
}
