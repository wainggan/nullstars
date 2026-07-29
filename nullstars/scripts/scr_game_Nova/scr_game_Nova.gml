// Feather ignore GM1051
#macro SETUP_OBJ_NOVA \
	fn_tick := obj_game_Nova_fn_tick; \
	fn_draw := obj_game_Nova_fn_draw; \
	priority := 1; \
	x_vel = 0; \
	y_vel = 0; \
	buffer_jump = 0;

function obj_game_Nova_fn_tick() {
	var _root := ns_root();
	var _config := ns_config();
	
	buffer_jump -= 1;
	
	var _k_hor := ns_control().check("right") - ns_control().check("left");
	var _k_ver := ns_control().check("right") - ns_control().check("left");
	var _k_jump_p := ns_control().check_pressed("jump");
	var _k_jump := ns_control().check("jump");
	
	if _k_jump_p {
		buffer_jump = _config.nova_buffer_jump;
	}
	
	var _onground := obj_Body_collision(x, y + 1);
	
	var _x_accel = 0;
	if abs(x_vel) > _config.nova_move_speed && _k_hor == sign(x_vel) {
		if _onground {
			_x_accel = _config.nova_move_slowdown;
		}
		else {
			_x_accel = _config.nova_move_slowdown_air;
		}
	}
	else {
		if abs(x_vel) > _config.nova_move_speed && _k_hor == -sign(x_vel) {
			_x_accel = _config.nova_move_accel_fast;
		}
		else {
			_x_accel = _config.nova_move_accel;
		}
	}
	
	x_vel = approach(x_vel, _k_hor * _config.nova_move_speed, _x_accel);
	
	var _y_accel = 0;
	
	if _k_jump {
		if abs(y_vel) < _config.nova_gravity_peak_thresh {
			_y_accel = _config.nova_gravity_peak;
		}
		else {
			_y_accel = _config.nova_gravity_hold;
		}
	}
	else {
		_y_accel = _config.nova_gravity;
	}
	
	if y_vel >= _config.gen_terminal_vel {
		_y_accel = _config.nova_gravity_term;
	}
	
	if (ns_control().check_released("jump")) && y_vel < 0 {
		y_vel *= _config.nova_jump_damp;
	}
	
	var _term_vel = _config.gen_terminal_vel;
	if _k_ver == 1 {
		_term_vel = _config.nova_terminal_vel_fast;
	}
	if _k_jump {
		_term_vel -= _config.nova_terminal_vel_hold;
	}
	
	if !_onground {
		y_vel = approach(y_vel, _term_vel, _y_accel);
	}
	
	if buffer_jump > 0 && _onground {
		buffer_jump = 0
		y_vel = -_config.nova_jump_vel;
	}
	
	static __oncollide_x := function () {
		x_vel = 0;
	};
	
	static __oncollide_y := function () {
		y_vel = 0;
	};
	
	obj_Body_move_x(x_vel, __oncollide_x);
	obj_Body_move_y(y_vel, __oncollide_y);
}

function obj_game_Nova_fn_draw() {
	draw_self();
}
