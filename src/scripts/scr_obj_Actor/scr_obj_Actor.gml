
/// @arg {id.Instance} _other
/// @return {bool}
/// @self obj_Actor
function obj_actor_riding(_other) {
	return place_meeting(x, y + 1, _other);
}

/// @self obj_Actor
function obj_actor_squish(_data) {
	return;
}

/// @self obj_Actor
function obj_actor_lift_get_x() {
	if lift_x == 0 && lift_y == 0 {
		return lift_last_x;
	}
	return lift_x;
}

/// @self obj_Actor
function obj_actor_lift_get_y() {
	if lift_x == 0 && lift_y == 0 {
		return lift_last_y;
	}
	return lift_y;
}

/// @self obj_Actor
function obj_actor_lift_set(_x, _y) {
	lift_x = _x;
	lift_y = _y;
	if _x != 0 || _y != 0 {
		lift_last_x = _x;
		lift_last_y = _y;
		lift_last_time = 10;
	}
}

/// should be called *after* the object has completed its main update
/// @self obj_Actor
function obj_actor_lift_update() {
	self.fn_lift_set(0, 0);
	lift_last_time -= 1;
	if lift_last_time <= 0 {
		lift_last_x = 0;
		lift_last_y = 0;
	}
}

/// @self obj_Actor
function obj_actor_move_x(_amount, _callback = undefined, _pusher = noone) {
	
	static __data = {
		target_x: 0,
		target_y: 0,
		pusher: noone,
	};
	
	x_rem += _amount;
	
	var _move = round(x_rem);
	if _move != 0 {
		
		x_rem -= _move;
		var _sign = sign(_move);
		
		while _move != 0 {
			if !self.fn_collision(x + _sign, y) {
				x += _sign;
				_move -= _sign;
			} else {
				if _callback != undefined {
					__data.pusher = _pusher;
					__data.target_x = x + _sign;
					__data.target_y = y;
					_callback(__data);
				}
				break;
			}
		}
		
	}
	
}

/// @self obj_Actor
function obj_actor_move_y(_amount, _callback = undefined, _pusher = noone) {
	
	static __data = {
		target_x: 0,
		target_y: 0,
		pusher: noone,
	};
	
	y_rem += _amount;
	
	var _move = round(y_rem);
	if _move != 0 {
		
		y_rem -= _move;
		var _sign = sign(_move);
		
		while _move != 0 {
			if !self.fn_collision(x, y + _sign) {
				y += _sign;
				_move -= _sign;
			} else {
				if _callback != undefined {
					__data.pusher = _pusher;
					__data.target_x = x;
					__data.target_y = y + _sign;
					_callback(__data);
				}
				break;
			}
		}
		
	}
	
}

// todo: optimize?
/// @self obj_Actor
function obj_actor_collision(_x, _y) {
	
	static __list = ds_list_create();
	
	var _loaded = global.game.level.loaded;
	for (var i = 0, _len = array_length(_loaded); i < _len; i++) {
		if place_meeting(_x, _y, _loaded[i].data.tiles) {
			return true;
		}
	}
	
	ds_list_clear(__list);
	instance_place_list(_x, _y, obj_Solid, __list, false);
	
	for (var i = 0, _len = ds_list_size(__list); i < _len; i++) {
		var _o = __list[| i];
		if _o.collidable {
			var _object_index = _o.object_index;
			
			if object_get_parent(_object_index) == obj_ss {
				
				if _object_index == obj_ss_up && _o.bbox_top >= bbox_bottom {
					return true;
				}
				if _object_index == obj_ss_down && _o.bbox_bottom <= bbox_top {
					return true;
				}
				if _object_index == obj_ss_left && _o.bbox_left >= bbox_right {
					return true;
				}
				if _object_index == obj_ss_right && _o.bbox_right <= bbox_left {
					return true;
				}
				
			} else {
				return true;
			}
		}
	}
	
	return false;
}


