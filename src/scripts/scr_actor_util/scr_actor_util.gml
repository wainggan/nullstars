
function actor_scan(_x, _y, _dir, _cap = 16) {
	// cache alloc
	static __return = {
		x: 0,
		y: 0,
	};
	
	var _off_x;
	var _off_y;
	
	var _check_x = _x;
	var _check_y = _y;
	
	// _dir is 0 | 1 | 2 | 3
	switch _dir {
		case 0: {
			_off_x = 1;
			_off_y = 0;
		} break;
		case 1: {
			_off_x = 0;
			_off_y = -1;
		} break;
		case 2: {
			_off_x = -1;
			_off_y = 0;
		} break;
		case 3: {
			_off_x = 0;
			_off_y = 1;
		} break;
		default: {
			__return.x = _check_x;
			__return.y = _check_y;
			return __return;
		}
	}
	
	var _check = _cap;
	
	// while not overflowing
	while _check > 0 {
		if actor_collision(_check_x, _check_y) {
			// we are inside a wall
			if _check_x == _x && _check_y == _y {
				break;
			}
			
			_check_x -= (sprite_width + (TILESIZE - 1)) * _off_x;
			_check_y -= (sprite_height + (TILESIZE - 1)) * _off_y;
			
			// todo: is this actually safe?
			if _off_x == 1 {
				// round down
				_check_x = _check_x & 0xffff_ffff_ffff_fffc;
			} else if _off_x == -1 {
				// round up
				_check_x = (_check_x | 0b11) + 1;
			}
			if _off_y == 1 {
				// round down
				_check_y = _check_y & 0xffff_ffff_ffff_fffc;
			} else if _off_y == -1 {
				// round up
				_check_y = (_check_y | 0b11) + 1;
			}
			
			var _check_2 = max(sprite_width div 4 + 1, sprite_height div 4 + 1);
			while !actor_collision(_check_x + _off_x * 4, _check_y + _off_y * 4) && _check_2 > 0 {
				_check_x += _off_x * 4;
				_check_y += _off_y * 4;
				_check_2--;
			}
	
			break;
		}
		
		_check_x += (sprite_width + (TILESIZE - 1)) * _off_x;
		_check_y += (sprite_height + (TILESIZE - 1)) * _off_y;
		
		_check--;
	}

	__return.x = _check_x;
	__return.y = _check_y;
	
	return __return;
}

function actor_check(_x, _y, _dir, _target, _cap = undefined) {
	return actor_check_scan(_x, _y, _dir, _target, _cap)[0];
}

/// exists for optimization.
/// 
/// @return Array<Real> [0]: Bool = if hit actor, [1]: { x: Real, y: Real } = scan data
function actor_check_scan(_x, _y, _dir, _target, _cap = undefined) {
	static __out = array_create(2);
	
	var _ = actor_scan(_x, _y, _dir, _cap);
	__out[1] = _;
	
	var _x1 = min(_x, _.x) + 1;
	var _y1 = min(_y, _.y) + 1;
	var _x2 = max(_x + sprite_width, _.x + sprite_width) - 1;
	var _y2 = max(_y + sprite_height, _.y + sprite_height) - 1;
	
	var _paranoia = __out;

	with _target {
		if rectangle_in_rectangle(
			bbox_left, bbox_top,
			bbox_right, bbox_bottom,
			_x1, _y1, _x2, _y2
		) {
			_paranoia[0] = true;
			return _paranoia;
		}
	}
	
	__out[0] = false;
	return __out;
}

function actor_stretch(_x1, _y1, _x2, _y2, _inst = self) {
	with _inst {
		x = _x1;
		y = _y1;
		image_xscale = abs(_x2 - _x1) / sprite_get_width(sprite_index);
		image_yscale = abs(_y2 - _y1) / sprite_get_height(sprite_index);
	}
}
