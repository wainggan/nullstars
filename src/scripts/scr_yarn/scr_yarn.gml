
function Yarn(_x = 0, _y = 0) constructor {
	x = _x;
	y = _y;
	
	direction = 0;
	
	/// @arg {struct.Yarn} _previous
	/// @arg {real} _dir
	/// @arg {real} _length
	/// @arg {real} _x_move
	/// @arg {real} _y_move
	/// @arg {real} _weight
	/// @arg {real} _damp
	/// @arg {real} _leeway
	static update = function (
		_previous = undefined,
		_dir = undefined,
		_length = 1,
		_x_move = 0,
		_y_move = 0,
		_weight = 1,
		_damp = 1,
		_leeway = 0,
	) {
		var _last_x = _previous != undefined ? _previous.x : x;
		var _last_y = _previous != undefined ? _previous.y : y;
		var _last_dir = _previous != undefined ? _previous.direction : undefined;
		
		var _target_x = x;
		var _target_y = y;
		
		if _last_dir != undefined {
			// direction to previous point
			direction = point_direction(x, y, _last_x, _last_y);
			
			// then we lerp towards the previous point's direction
			var _diff = angle_difference(direction, _last_dir);
			_diff *= _damp;
			direction = _last_dir + _diff;
			
			if _dir != undefined {
				direction = _dir;
			}
			
			// force into place
			_target_x -= lengthdir_x(_weight, direction);
			_target_y -= lengthdir_y(_weight, direction);
		} else {
			if _dir != undefined {
				direction = _dir;
			}
		}
		
		_target_x += _x_move;
		_target_y += _y_move;
		
		var _angle_snap = point_direction(_target_x, _target_y, _last_x, _last_y);
		
		var _new_x = _last_x - lengthdir_x(_length, _angle_snap);
		var _new_y = _last_y - lengthdir_y(_length, _angle_snap);
		
		x = lerp(_new_x, _target_x, _leeway);
		y = lerp(_new_y, _target_y, _leeway);
	};
}

