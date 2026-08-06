/// @self obj_game_Nova
function obj_game_Nova_fn_create() {
	obj_Body_fn_create();
	
	// # nova
	// nova has a lot of bullshit. this might be the messiest
	// part of the game, simply because of how many edge cases and
	// considerations and micro-adjustments there are, to make
	// nova feel just a little better to control.
	// even worse, I can't even fit that many ASSERT()s here ;_;
	
	// ## overrides.
	self.fn_tick := obj_game_Nova_fn_tick;
	self.body_strong := false;
	self.body_priority := 1;
	
	// ## nova specifics
	
	// velocity.
	self.x_vel = 0;
	self.y_vel = 0;
	
	// simulate holding the jump key.
	self.hold_jump_key_timer = 0;
	
	// force y_vel to stick to a value.
	self.force_y_vel_value = 0;
	self.force_y_vel_timer = 0;
	
	self.release_jump_buffer_timer = 0;
	
	self.buffer_jump = 0;
	
	self.state := calico_create(obj_game_Nova_get_state_base(), self);
	calico_change(self.state, obj_game_Nova_STATE_FREE);
}

#macro obj_game_Nova_STATE_GENERIC "base"
#macro obj_game_Nova_STATE_FREE "free"

#macro obj_game_Nova_EVENT_TICK "tick"

/// @self obj_game_Nova
function obj_game_Nova_state_generic(_state, _data) {
	var _config := ns_config();
	
	self.buffer_jump -= ns_deltatime();
	if ns_control_press(ns_control_JUMP) {
		self.buffer_jump = _config.nova_buffer_jump;
	}
	
	calico_child(_state);
	
	static __oncollide_x := function () {
		self.x_vel = 0;
	};
	
	static __oncollide_y := function () {
		self.y_vel = 0;
	};
	
	obj_Body_move_x(self.x_vel * ns_deltatime(), __oncollide_x);
	obj_Body_move_y(self.y_vel * ns_deltatime(), __oncollide_y);
}

/// @arg {real} _value
/// @arg {real} _timer
/// @self obj_game_Nova
function obj_game_Nova_set_force_y_vel(_value, _timer) {
	self.force_y_vel_value = _value;
	self.force_y_vel_timer = _timer;
}

/// @self obj_game_Nova
function obj_game_Nova_jump_normal_set_start() {
	var _config := ns_config();
	
	self.y_vel = min(self.y_vel, -_config.nova_jump_vel);
	obj_game_Nova_set_force_y_vel(self.y_vel, _config.nova_jump_time);
}

/// @self obj_game_Nova
function obj_game_Nova_jump_normal_set_release() {
	var _config := ns_config();
	
	self.y_vel *= _config.nova_jump_damp;
	obj_game_Nova_set_force_y_vel(0, 0);
}

/// @self obj_game_Nova
function obj_game_Nova_jump_normal() {
	var _config := ns_config();
	
	obj_game_Nova_jump_normal_set_start();
	
	if !ns_control_hold(ns_control_JUMP) {
		obj_game_Nova_jump_normal_set_release();
	}
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
	
	var _k_move = _k_hor;
	
	
	
	var _x_accel = 0;
	if abs(self.x_vel) > _config.nova_move_speed && _k_hor == sign(self.x_vel) {
		if _onground {
			_x_accel = _config.nova_move_slowdown;
		}
		else {
			_x_accel = _config.nova_move_slowdown_air;
		}
	}
	else {
		if abs(self.x_vel) > _config.nova_move_speed && _k_hor == -sign(self.x_vel) {
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
	
	if (_k_jump_r || self.release_jump_buffer_timer > 0) && y_vel < 0 {
		obj_game_Nova_jump_normal_set_release();
	}
	self.release_jump_buffer_timer = 0;
	
	var _term_vel = _config.gen_terminal_vel;
	if _k_ver == 1 {
		_term_vel = _config.nova_terminal_vel_fast;
	}
	
	if _k_jump {
		_term_vel -= _config.nova_terminal_vel_hold;
	}
	
	if self.force_y_vel_timer > 0 {
		self.force_y_vel_timer -= 1;
		if _k_jump {
			self.y_vel = self.force_y_vel_value;
		}
		else {
			self.force_y_vel_timer = 0;
		}
	}
	else {
		if !_onground {
			self.y_vel = approach(self.y_vel, _term_vel, _y_accel * ns_deltatime());
		}
	}
	
	if buffer_jump > 0 && _onground {
		buffer_jump = 0
		
		obj_game_Nova_jump_normal_set_start();
		
		if !_k_jump {
			self.release_jump_buffer_timer = 1;
		}
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
