
target = obj_player;

x_sod = new Sod().set_accuracy();
y_sod = new Sod().set_accuracy();

target_x = 0;
target_y = 0;

roomsnap_timer = 0
roomsnap_last = noone;
roomsnap_last_inside = false;
roomsnap_cooldown = 0;

shake_time = 0;
shake_damp = 1;

update = function(_anim = true) {
	
	var _cam = game_camera_get();

	if instance_exists(target) {
		static __out = {
			x: x, y: y
		};
		__out.x = x;
		__out.y = y;
		target.cam(__out); // bandage
		target_x = __out.x;
		target_y = __out.y;
	}

	var _tx = target_x, _ty = target_y;
	var _ts = 0.025;
	
	var _weights = collision_point(_tx, _ty, obj_camera_focus, true, true);
	
	if _weights != noone {
		var _dist = point_distance(target_x, target_y, _weights.x, _weights.y);
		_tx = lerp(_tx, _weights.x, max(0, 1 - power(_dist / _weights.sprite_width * 2, _weights.weight)));
		_ty = lerp(_ty, _weights.y, max(0, 1 - power(_dist / _weights.sprite_height * 2, _weights.weight)));
		if _weights.force {
			_tx = _weights.x;
			_ty = _weights.y;
		}
	}
	
	var _scale = 128;
	
	var _f = 420;
	var _final_tx = 0;
	var _final_ty = 0;
	
	with obj_camera_room {
		
		var _d = sdf(_tx, _ty, x, y, x + sprite_width, y + sprite_height) / sqrt(_scale);
		
		var _s = 1;
		
		var _p = _s <= 0 ? hmin(_f, _d) : smin(_f, _d, _s);
		_f = _p[0];
		
		var _self_tx = _tx;
		if unlock_x {
			if sprite_width <= _cam.w {
				_self_tx = x + sprite_width / 2;
			} else {
				_self_tx = clamp(_tx, x + _cam.w / 2, x + sprite_width - _cam.w / 2);
			}
		}
		var _self_ty = _ty;
		if unlock_y {
			if sprite_height <= _cam.h {
				_self_ty = y + sprite_height / 2;
			} else {
				_self_ty = clamp(_ty, y + _cam.h / 2, y + sprite_height - _cam.h / 2);
			}
		}
		
		_final_tx = lerp(_final_tx, _self_tx, _p[1]);
		_final_ty = lerp(_final_ty, _self_ty, _p[1]);
	}
	
	var _k = 1;
	with obj_camera_room {
		var _d = (sdf(
				_tx, _ty,
				x + crop_x1 * TILESIZE, y + crop_y1 * TILESIZE,
				x + sprite_width - crop_x2 * TILESIZE,
				y + sprite_height - crop_y2 * TILESIZE
			) - _scale) / _scale;
		_k -= power(clamp(-_d, 0, 1), 2);
	}
	_k = max(_k, 0);
	
	_final_tx = lerp(_final_tx, _tx, _k);
	_final_ty = lerp(_final_ty, _ty, _k);
	
	_tx = _final_tx;
	_ty = _final_ty;
	
	
//
	//var _weights = collision_point(_tx, _ty, obj_camera_focus, true, true);
//
	//if _weights != noone {
		//var _dist = point_distance(target_x, target_y, _weights.x, _weights.y);
		//_tx = lerp(_tx, _weights.x, max(0, 1 - power(_dist / _weights.sprite_width * 2, _weights.weight)));
		//_ty = lerp(_ty, _weights.y, max(0, 1 - power(_dist / _weights.sprite_height * 2, _weights.weight)));
		//if _weights.force {
			//_tx = _weights.x;
			//_ty = _weights.y;
		//}
	//}
//
	//_weights = noone;
	//var _inside = true;
//
	//with obj_camera_room {
		//var _check = collision_point(_tx, _ty, self, true, false);
		//if _check != noone && (_weights == noone || _check.priority > _weights.priority) {
			//_weights = _check;
			//_inside = true;
		//} else {
			//continue;
		//}
		//if !point_in_rectangle(
			//_tx, _ty, 
			//x + crop_x1 * TILESIZE, y + crop_y1 * TILESIZE, 
			//x + sprite_width - crop_x2 * TILESIZE,
			//y + sprite_height - crop_y2 * TILESIZE
		//) _inside = false;
	//}
//
	//var _changed = false;
//
	//if _weights != noone {
	//
	//
		//if _inside && _weights.unlock_x {
			//if _weights.sprite_width <= _cam_w {
				//_tx = _weights.x + _weights.sprite_width / 2;
			//} else {
				//_tx = clamp(_tx, _weights.x + _cam_w / 2, _weights.x + _weights.sprite_width - _cam_w / 2)
			//}
			//_changed = true;
		//}
	//
		//if _inside && _weights.unlock_y {
			//if _weights.sprite_height <= _cam_h {
				//_ty = _weights.y + _weights.sprite_height / 2;
			//} else {
				//_ty = clamp(_ty, _weights.y + _cam_h / 2, _weights.y + _weights.sprite_height - _cam_h / 2)
			//}
			//_changed = true;
		//} 
	//
	//}
//
	//if !_changed {
		//_weights = noone;
	//}
//
	//roomsnap_cooldown -= 1;
	//if roomsnap_last != _weights || roomsnap_last_inside != _changed {
		//roomsnap_timer = 1;
	//}
	//roomsnap_last = _weights
	//roomsnap_last_inside = _changed;
	//
	//roomsnap_timer = approach(roomsnap_timer, 0, 0.08);
	//_ts = lerp(_ts, 0.01, roomsnap_timer);
//
	//// bad idea
	//if target == obj_player_death {
		//_ts = 0.8
	//}

	/*
	var _w = room_width, _h = room_height;

	if instance_exists(level) {
		_w = level.max_width;
		_h = level.max_height;
	}

	_tx = clamp(_tx, _cam_w / 2, _w - _cam_w / 2);
	_ty = clamp(_ty, _cam_h / 2, _h - _cam_h / 2);
	*/
	if _anim {
		x_sod.set_weights(_ts, 1, 0.25);
		y_sod.set_weights(_ts, 1, 0.25);
		x_sod.update(_tx);
		y_sod.update(_ty);

		x = x_sod.get_value();
		y = y_sod.get_value();
	} else {
		x = _tx;
		y = _ty;
		x_sod.set_value(x);
		y_sod.set_value(y);
	}
	
	var _shake_dir = irandom_range(0, 360);
	var _shake_x = round(lengthdir_x(shake_time, _shake_dir));
	var _shake_y = round(lengthdir_y(shake_time, _shake_dir));
	switch global.settings.graphic.screenshake {
		case 0:
			_shake_x = 0;
			_shake_y = 0;
			break;
		case 1:
			_shake_x *= 0.5;
			_shake_y *= 0.5;
			break;
		default:
			break;
	}

	camera_set_view_pos(
		view_camera[0], 
		floor(x - _cam.w / 2) + _shake_x, 
		floor(y - _cam.h / 2) + _shake_y
	);

};

