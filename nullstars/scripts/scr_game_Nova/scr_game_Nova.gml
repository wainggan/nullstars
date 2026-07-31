/// @self obj_game_Nova
function obj_game_Nova_fn_create() {
	obj_Body_fn_create();
	
	fn_tick := obj_game_Nova_fn_tick;
	priority := 1;
	
	x_vel = 0;
	y_vel = 0;
	buffer_jump = 0;
	
	state := calico_create(obj_game_Nova_get_state_base(), self);
	calico_change(state, obj_game_Nova_STATE_FREE);
}

#macro obj_game_Nova_STATE_GENERIC "base"
#macro obj_game_Nova_STATE_FREE "free"

#macro obj_game_Nova_EVENT_TICK "tick"

/// @self obj_game_Nova
function obj_game_Nova_state_generic(_state, _data) {
	var _config := ns_config();
	
	buffer_jump -= ns_deltatime();
	if ns_control_press(ns_control_JUMP) {
		buffer_jump = _config.nova_buffer_jump;
	}
	
	calico_child(_state);
	
	static __oncollide_x := function () {
		x_vel = 0;
	};
	
	static __oncollide_y := function () {
		y_vel = 0;
	};
	
	obj_Body_move_x(x_vel * ns_deltatime(), __oncollide_x);
	obj_Body_move_y(y_vel * ns_deltatime(), __oncollide_y);
}

/// @self obj_game_Nova
function obj_game_Nova_state_free(_state, _data) {
	var _root := ns_root();
	var _config := ns_config();
	
	var _k_hor := ns_control_hold(ns_control_RIGHT) - ns_control_hold(ns_control_LEFT);
	var _k_ver := ns_control_hold(ns_control_DOWN) - ns_control_hold(ns_control_UP);
	var _k_jump_p := ns_control_press(ns_control_JUMP);
	var _k_jump_r := ns_control_release(ns_control_JUMP);
	var _k_jump := ns_control_hold(ns_control_JUMP);
	
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
	
	x_vel = approach(x_vel, _k_hor * _config.nova_move_speed, _x_accel * ns_deltatime());
	
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
	
	if _k_jump_r && y_vel < 0 {
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
		y_vel = approach(y_vel, _term_vel, _y_accel * ns_deltatime());
	}
	
	if buffer_jump > 0 && _onground {
		buffer_jump = 0
		y_vel = -_config.nova_jump_vel;
	}
	
	calico_child(_state);
}

/// @self obj_game_Nova
function obj_game_Nova_get_state_base() {
	static __base = undefined;
	
	if __base == undefined {
		__base := calico_base_create();
		
		calico_base_add(__base, obj_game_Nova_STATE_GENERIC);
		calico_base_event(__base, obj_game_Nova_STATE_GENERIC, obj_game_Nova_EVENT_TICK, obj_game_Nova_state_generic);
		calico_base_add(__base, obj_game_Nova_STATE_FREE, obj_game_Nova_STATE_GENERIC);
		calico_base_event(__base, obj_game_Nova_STATE_FREE, obj_game_Nova_EVENT_TICK, obj_game_Nova_state_free);
	}
	
	return __base;
}

/// @self obj_game_Nova
function obj_game_Nova_fn_tick() {
	calico_run(self.state, obj_game_Nova_EVENT_TICK);
}
