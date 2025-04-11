
/// moves a solid, moving any actors that are in the way or are "riding" the solid.
/// when an actor is moved and `_lift` is true, the actor's `lift_#` variables are
/// set to `_xv` and `_yv`. if `_lift_x` != undefined, then `_xv` and `_yv` are set to
/// `_lift_x` and `_lift_y` respectively.
/// 
/// @arg {Real} _xv
/// @arg {Real} _yv
/// @arg {Bool} [_lift] true by default.
/// @arg {Real} [_lift_x]
/// @arg {Real} [_lift_y]
function solid_move(_xv, _yv, _lift = true, _lift_x = undefined, _lift_y = undefined) {
	
	static __riding = [];
	array_delete(__riding, 0, array_length(__riding));
	with obj_Actor {
		if riding(other) array_push(__riding, self);
	}
	
	x_rem += _xv;
	y_rem += _yv;
	
	if _lift {
		if _lift_x != undefined {
			lift_x = _lift_x;
			lift_y = _lift_y;
		} else {
			lift_x = _xv;
			lift_y = _yv;
		}
	}
	
	var _moveX = round(x_rem);
	var _moveY = round(y_rem);
	
	if _moveX != 0 || _moveY != 0 {
		
		if _moveX != 0 {
			x_rem -= _moveX;
			x += _moveX;
			
			if collidable {
				collidable = false;
				if _moveX > 0 {
					with obj_Actor {
						if place_meeting(x, y, other) {
							actor_move_x(other.bbox_right - bbox_left, squish, other);
							if _lift actor_lift_set(other.lift_x, other.lift_y);
						} else if array_get_index(__riding, self) != -1 {
							actor_move_x(_moveX);
							if _lift actor_lift_set(other.lift_x, other.lift_y);
						}
					}
				} else {
					with obj_Actor {
						if place_meeting(x, y, other) {
							actor_move_x(other.bbox_left - bbox_right, squish, other);
							if _lift actor_lift_set(other.lift_x, other.lift_y);
						} else if array_get_index(__riding, self) != -1 {
							actor_move_x(_moveX);
							if _lift actor_lift_set(other.lift_x, other.lift_y);
						}
					}
				}
				collidable = true;
			}
		}
		
		if _moveY != 0 {
			y_rem -= _moveY;
			y += _moveY;
			
			if collidable {
				collidable = false;
				if _moveY > 0 {
					with obj_Actor {
						if place_meeting(x, y, other) {
							actor_move_y(other.bbox_bottom - bbox_top, squish, other);
							if _lift actor_lift_set(other.lift_x, other.lift_y);
						} else if array_get_index(__riding, self) != -1 {
							actor_move_y(_moveY);
							if _lift actor_lift_set(other.lift_x, other.lift_y);
						}
					}
				} else {
					with obj_Actor {
						if place_meeting(x, y, other) {
							actor_move_y(other.bbox_top - bbox_bottom, squish, other);
							if _lift actor_lift_set(other.lift_x, other.lift_y);
						} else if array_get_index(__riding, self) != -1 {
							actor_move_y(_moveY);
							if _lift actor_lift_set(other.lift_x, other.lift_y);
						}
					}
				}
				collidable = true;
			}
		}
	}
	
}


