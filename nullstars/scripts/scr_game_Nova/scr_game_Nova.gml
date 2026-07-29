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
	var _kj := keyboard_check(ord("J"));
	
	var _onground := obj_Body_collision(x, y + 1);
	
	if _kj && _onground {
		y_vel = -5;
	}
	
	x_vel = approach(x_vel, _kh * 4, 1);
	y_vel += 0.3 - _kj * 0.15;
	
	static __oncollide_x := function () {
		x_vel = 0;
	};
	
	static __oncollide_y := function () {
		y_vel = 0;
	};
	
	obj_Body_move_x(round(x_vel), __oncollide_x);
	obj_Body_move_y(round(y_vel), __oncollide_y);
}

function obj_game_Nova_fn_draw() {
	draw_self();
}
