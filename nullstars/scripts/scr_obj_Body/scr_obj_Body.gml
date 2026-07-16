/*
a Body represents an in-game object that can collide with other Bodys.
*/

/*
collide
	whether other bodys should consider this one 'collidable'
strong
	whether this body is 'solid'. solid bodys may not overlap
	another body, and they are able to push other bodys.
priority
	determines push priority. bodys with higher priorities
	can push bodys with lower priorities.
*/

// Feather ignore GM1051
#macro SETUP_OBJ_BODY \
	collide = true; \
	strong = true; \
	priority = 0; \
	fn_riding := obj_Body_fn_riding; \
	fn_squish := obj_Body_fn_squish; \
	fn_move_blunt := obj_Body_fn_move_blunt;

/// @self obj_Body
function obj_Body_fn_squish() {
	instance_destroy();
}

/// @self obj_Body
function obj_Body_fn_riding(_other) {
	return false;
}

/// moves the Body.
///
/// `_axis` is `true` for the x-axis, and `false for the y-axis. `_vel` is
/// how many pixels the Body should move, though the Body won't neccessarily move
/// that much (e.g. other Bodys in the way).
/// `_oncollide` is an optional callback that runs if the Body was not able to move
/// exactly `_vel` pixels. its first argument will be the body that is causing the squish.
/// `_pusher`, if provided, is the body causing this function to be called, and should
/// not be used except for within this function.
///
/// notably, this function does not take account of pure solids, like tiles or semisolids.
///
/// @self obj_Body
/// @arg {bool} _axis
/// @arg {real} _vel
/// @arg {function} _oncollide
/// @arg {id.obj_Body} _pusher
function obj_Body_fn_move_blunt(_axis, _vel, _oncollide = undefined, _pusher = undefined) {
	_vel := round(_vel);
	
	var _sign := sign(_vel);
	
	if _sign == 0 {
		return;
	}
	
	// maintaining a stack of ds_lists because this function is recursive.
	static __list := [];
	static __index = 0;
	
	if array_length(__list) == __index {
		array_push(__list, ds_list_create());
	}
	
	var _list := __list[__index++];
	
	// step 1: resolve all priority collisions
	// this calculates exactly how far we can move until we touch another solid body.
	
	var _len;
	
	ds_list_clear(_list);
	
	if _axis {
		_len := instance_place_list(self.x + _vel, self.y, obj_Body, _list, false);
	}
	else {
		_len := instance_place_list(self.x, self.y + _vel, obj_Body, _list, false);
	}
	
	var _vel_wall = _vel;
	var _collided = false;
	
	for (var i = 0; i < _len; i++) {
		var _other := _list[| i];
		
		// filter for higher priority
		if _other.priority < self.priority {
			continue;
		}
		
		// filter for solids
		if !_other.strong {
			continue;
		}
		
		_collided = true;
		
		if _sign == 1 {
			var _diff;
			if _axis {
				_diff := _other.bbox_left - self.bbox_right;
			}
			else {
				_diff := _other.bbox_top - self.bbox_bottom;
			}
			
			if _diff < _vel_wall {
				_vel_wall = _diff;
			}
		}
		else {
			var _diff;
			if _axis {
				_diff := _other.bbox_right - self.bbox_left;
			}
			else {
				_diff := _other.bbox_bottom - self.bbox_top;
			}
			
			if _diff > _vel_wall {
				_vel_wall = _diff;
			}
		}
	}
	
	// _vel_wall is now 'clipped'
	
	if self.strong {
		// step 2: resolve all non-priority collisions
	
		ds_list_clear(_list);
	
		if _axis {
			_len = instance_place_list(self.x + _vel_wall, self.y, obj_Body, _list, false);
		}
		else {
			_len = instance_place_list(self.x, self.y + _vel_wall, obj_Body, _list, false);
		}
		
		var _last_collide := obj_Entity_get_collidable();
		obj_Entity_set_collidable(false);
	
		for (var i = 0; i < _len; i++) {
			var _other := _list[| i];
		
			// filter for lower priority
			if _other.priority >= self.priority {
				continue;
			}
		
			var _diff;
			if _sign == 1 {
				if _axis {
					_diff := (self.bbox_right + _vel_wall) - _other.bbox_left;
				}
				else {
					_diff := (self.bbox_bottom + _vel_wall) - _other.bbox_top;
				}
			}
			else {
				if _axis {
					_diff := (self.bbox_left + _vel_wall) - _other.bbox_right;
				}
				else {
					_diff := (self.bbox_top + _vel_wall) - _other.bbox_bottom;
				}
			}
			
			// move forward so _other's squish method can
			// recognize where we are supposed to be.
			// this is fine, because we are not collidable right now.
			if _axis {
				self.x += _vel_wall;
			}
			else {
				self.y += _vel_wall;
			}

			// passing in _other's squish method to _oncollide, since
			// if the _other collides with anything, that means we
			// are about to overlap it (and solid bodys may not overlap
			// anything). squish will ensure this doesn't happen (probably
			// eliminating _other).
			_other.fn_move_blunt(_axis, _diff, _other.fn_squish, self);
			
			if _axis {
				self.x -= _vel_wall;
			}
			else {
				self.y -= _vel_wall;
			}
		}
		
		obj_Entity_set_collidable(_last_collide);
	
		with obj_Body {
			if self.fn_riding(other) {
				self.fn_move_blunt(_axis, _vel_wall, , self);
			}
		}
	}
	
	if _axis {
		self.x += _vel_wall;
	}
	else {
		self.y += _vel_wall;
	}
	
	if _collided {
		if _oncollide != undefined {
			_oncollide(_pusher);
		}
	}
	
	__index--;
}

/**
@self asset.obj_Body
*/
function obj_Body_move_x(_vel, _oncollide = undefined) {
	self.fn_move_blunt(true, _vel, _oncollide);
}

/**
@self asset.obj_Body
*/
function obj_Body_move_y(_vel, _oncollide = undefined) {
	self.fn_move_blunt(false, _vel, _oncollide);
}
