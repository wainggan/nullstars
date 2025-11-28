
/// override
/// @self obj_player
function obj_player_impl() {
	static __return = ["bounce"];
	return __return;
}

/// @self obj_player
function obj_player_get_crouch() {
	return mask_index == spr_hitbox_player_crouch;
}

/// @self obj_player
function obj_player_set_crouch(_value) {
	if _value {
		mask_index = spr_hitbox_player_crouch;
	} else {
		mask_index = spr_hitbox_player;
	}
}

/// @self obj_player
function obj_player_get_can_uncrouch() {
	if !self.fn_get_crouch() {
		return true;
	}
	
	var _pre = mask_index;
	mask_index = spr_hitbox_player;
	
	var _collide = self.fn_collision(x, y);
	var _inst = instance_place(x, y, obj_ss_down);
	if _inst != noone {
		_collide = true;
	}
	
	mask_index = _pre;
	return !_collide;
}

/// overrides obj_entity_cam
/// @self obj_player
function obj_player_cam(_cam) {
	if state.is(state_free) && onground {
		cam_ground_x = x + dir * 64;
		cam_ground_y = y - 32;
	}
	
	var _dist = point_distance(cam_ground_x, cam_ground_y, x, y);
	
	var _x = x + power(abs(x_vel), 1.4) * sign(x_vel);
	var _y = y - 32;
	
	if state.is(state_cannon) {
		_y = y - 16;
	}
	
	/*
	if state.is(state_menu) {
		_x += 48 + (array_length(menu.stack) - 1) * 12;
		_y += -4;
	}*/
	
	_x = lerp(cam_ground_x, _x, 1 - max(0, 1 - power(_dist / 64, 2)) * 0.0);
	_y = lerp(cam_ground_y, _y, 1 - max(0, 1 - power(_dist / 128, 2)) * 0.8);
	
	var _ = _cam.constrain(_x, _y);
	_cam.move(_.x, _.y);
}
