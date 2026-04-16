// Feather ignore GM1051
#macro SETUP_OBJ_NOVA \
	fn_tick := obj_game_Nova_fn_tick; \
	fn_draw := obj_game_Nova_fn_draw; \
	x_vel = 0; \
	y_vel = 0;

function obj_game_Nova_fn_tick() {
	
}

function obj_game_Nova_fn_draw() {
	draw_self();
}
