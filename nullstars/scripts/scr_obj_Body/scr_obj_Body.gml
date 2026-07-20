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
	ASSERT_EQ_DEBUG(_vel, round(_vel))
	
	var _sign := sign(_vel);
	
	if _sign == 0 {
		return;
	}
	
	// maintaining a stack of ds_lists, since this function is recursive.
	static __list := [];
	static __index = 0;
	
	if array_length(__list) == __index {
		array_push(__list, ds_list_create());
	}
	
	var _list := __list[__index++];
	
	// step 1: resolve all priority collisions
	// this calculates exactly how far we can move until we touch another solid body.
	
	var _len;
	
	var _vel_wall = _vel;
	var _collided = false;
	
	// the bounding box between now and where we want to go.
	var _area_left = self.bbox_left;
	var _area_right = self.bbox_right;
	var _area_top = self.bbox_top;
	var _area_bottom = self.bbox_bottom;
	
	if _axis {
		if _sign == 1 {
			_area_right += _vel_wall;
		}
		else {
			_area_left += _vel_wall;
		}
	}
	else {
		if _sign == 1 {
			_area_bottom += _vel_wall;
		}
		else {
			_area_top += _vel_wall;
		}
	}
	
	// first, deal with tilemaps.
	// in an ideal world, tilemaps could also be an obj_Body somehow.
	// unfortunately, that's likely just simply too slow.
	
	// tilemaps are a little messy to deal with. unfortunately this
	// function depends on a global understanding of the collision
	// data around self.
	
	// we don't need a fucked up stack like __list, since the lifetime of
	// this list's data isn't affected by recursion.
	static __tilemap_list := ds_list_create();
	
	ds_list_clear(__tilemap_list);
	
	// collect every tilemap
	_len := collision_rectangle_list(
		_area_left, _area_top, _area_right, _area_bottom,
		obj_room, false, true, __tilemap_list, false
	);
	
	for (var i = 0; i < _len; i++) {
		var _tilemap := __tilemap_list[| i].parent.layer_solid_tilemap;
		ASSERT_NE(_tilemap, undefined);
		
		var _tilemap_x := tilemap_get_x(_tilemap);
		var _tilemap_y := tilemap_get_y(_tilemap);
		var _tilemap_w := tilemap_get_width(_tilemap);
		var _tilemap_h := tilemap_get_height(_tilemap);
		
		// calculate exactly what tiles in the tilemap we could possibly collide with
		var _bbtile_left := clamp((_area_left - _tilemap_x) div (TILE_SIZE), 0, _tilemap_w - 1);
		var _bbtile_right := clamp((_area_right - _tilemap_x - 1) div (TILE_SIZE), 0, _tilemap_w - 1);
		var _bbtile_top := clamp((_area_top - _tilemap_y) div (TILE_SIZE), 0, _tilemap_h - 1);
		var _bbtile_bottom := clamp((_area_bottom - _tilemap_y - 1) div (TILE_SIZE), 0, _tilemap_h - 1);
		
		// no goto :(
		var _exit = false;
		
		// evil nightmare if-else. these loops are oriented such that
		// we always scan from self outward.
		if _axis {
			if _sign == 1 {
				for (var _x = _bbtile_left; _x <= _bbtile_right; _x++) {
					for (var _y = _bbtile_top; _y <= _bbtile_bottom; _y++) {
						if tilemap_get(_tilemap, _x, _y) != 0 {
							_vel_wall = min(_vel_wall, (_x * (TILE_SIZE) + _tilemap_x) - self.bbox_right);
							_collided = true;
							_exit = true;
							break;
						}
					}
					
					if _exit {
						break;
					}
				}
			}
			else {
				for (var _x = _bbtile_right; _x >= _bbtile_left; _x--) {
					for (var _y = _bbtile_top; _y <= _bbtile_bottom; _y++) {
						if tilemap_get(_tilemap, _x, _y) != 0 {
							_vel_wall = max(_vel_wall, (_x * (TILE_SIZE) + _tilemap_x + (TILE_SIZE)) - self.bbox_left);
							_collided = true;
							_exit = true;
							break;
						}
					}
					
					if _exit {
						break;
					}
				}
			}
		}
		else {
			if _sign == 1 {
				for (var _y = _bbtile_top; _y <= _bbtile_bottom; _y++) {
					for (var _x = _bbtile_left; _x <= _bbtile_right; _x++) {
						if tilemap_get(_tilemap, _x, _y) != 0 {
							_vel_wall = min(_vel_wall, (_y * (TILE_SIZE) + _tilemap_y) - self.bbox_bottom);
							_collided = true;
							_exit = true;
							break;
						}
					}
					
					if _exit {
						break;
					}
				}
			}
			else {
				for (var _y = _bbtile_bottom; _y >= _bbtile_top; _y--) {
					for (var _x = _bbtile_left; _x <= _bbtile_right; _x++) {
						if tilemap_get(_tilemap, _x, _y) != 0 {
							_vel_wall = max(_vel_wall, (_y * (TILE_SIZE) + _tilemap_y + (TILE_SIZE)) - self.bbox_top);
							_collided = true;
							_exit = true;
							break;
						}
					}
					
					if _exit {
						break;
					}
				}
			}
		}
	}

	// now, deal with other bodies
	
	ds_list_clear(_list);
	
	// _vel_wall might have been clipped, refresh area.
	if _axis {
		if _sign == 1 {
			_area_right = self.bbox_right + _vel_wall;
		}
		else {
			_area_left = self.bbox_left + _vel_wall;
		}
	}
	else {
		if _sign == 1 {
			_area_bottom = self.bbox_bottom + _vel_wall;
		}
		else {
			_area_top = self.bbox_top + _vel_wall;
		}
	}
	
	_len := collision_rectangle_list(
		_area_left, _area_top, _area_right, _area_bottom,
		obj_Body, false, true, _list, false
	);
	
	for (var i = 0; i < _len; i++) {
		var _other := _list[| i];
		
		// skip non-solids and solids with weaker priorities
		if !_other.strong || _other.priority <= self.priority {
			continue;
		}
		
		_collided = true;
		
		// hard clip.
		if _axis {
			if _sign == 1 {
				_vel_wall = min(_vel_wall, _other.bbox_left - self.bbox_right);
			}
			else {
				_vel_wall = max(_vel_wall, _other.bbox_right - self.bbox_left);
			}
		}
		else {
			if _sign == 1 {
				_vel_wall = min(_vel_wall, _other.bbox_top - self.bbox_bottom);
			}
			else {
				_vel_wall = max(_vel_wall, _other.bbox_bottom - self.bbox_top);
			}
		}
	}
	
	// _vel_wall is now 'clipped', assuming that all non-priority
	// bodies are moved. speaking of:
	
	if self.strong {
		// step 2: resolve all non-priority collisions
		
		// refresh collision since velocity was clipped
		ds_list_clear(_list);
		
		// once again refresh the area.
		if _axis {
			if _sign == 1 {
				_area_right = self.bbox_right + _vel_wall;
			}
			else {
				_area_left = self.bbox_left + _vel_wall;
			}
		}
		else {
			if _sign == 1 {
				_area_bottom = self.bbox_bottom + _vel_wall;
			}
			else {
				_area_top = self.bbox_top + _vel_wall;
			}
		}
		
		_len := collision_rectangle_list(
			_area_left, _area_top, _area_right, _area_bottom,
			obj_Body, false, true, _list, false
		);
		
		// disable collisions to prevent collisions with self
		var _last_collide := obj_Entity_get_collidable();
		obj_Entity_set_collidable(false);
	
		for (var i = 0; i < _len; i++) {
			var _other := _list[| i];
		
			// skip solids with stronger priorities
			if _other.strong && _other.priority > self.priority {
				continue;
			}
		
			var _diff;
			if _axis {
				if _sign == 1 {
					// equivalent to
					// _diff := (self.bbox_right + _vel_wall) - _other.bbox_left;
					_diff := _area_right - _other.bbox_left;
				}
				else {
					_diff := _area_left - _other.bbox_right;
				}
				
				// move forward so _other's squish method can
				// recognize where we are supposed to be.
				// this is fine, because we are not collidable right now.
				// self.x += _vel_wall;
			}
			else {
				if _sign == 1 {
					_diff := _area_bottom - _other.bbox_top;
				}
				else {
					_diff := _area_top - _other.bbox_bottom;
				}
				
				// self.y += _vel_wall;
			}

			// passing in _other's squish method to _oncollide, since
			// if the _other collides with anything, that means we
			// are about to overlap it (and solid bodys may not overlap
			// anything). squish will ensure this doesn't happen (probably
			// eliminating _other).
			_other.fn_move_blunt(_axis, _diff, _other.fn_squish, self);
			
			//if _axis {
			//	self.x -= _vel_wall;
			//}
			//else {
			//	self.y -= _vel_wall;
			//}
		}
		
		obj_Entity_set_collidable(_last_collide);
	
		with obj_Body {
			if self.fn_riding(other) {
				self.fn_move_blunt(_axis, _vel_wall, , self);
			}
		}
	}
	
	// it is now safe to move blindly.
	
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
@arg {asset.obj_Body} _other
@return {bool}
*/
function obj_Body_riding(_other) {
	return self.fn_riding(_other);
}

function obj_Body_squish() {
	self.fn_squish();
}

/**
@arg {real} _vel
@arg {function} _oncollide
@self asset.obj_Body
*/
function obj_Body_move_x(_vel, _oncollide = undefined) {
	self.fn_move_blunt(true, _vel, _oncollide);
}

/**
@arg {real} _vel
@arg {function} _oncollide
@self asset.obj_Body
*/
function obj_Body_move_y(_vel, _oncollide = undefined) {
	self.fn_move_blunt(false, _vel, _oncollide);
}
