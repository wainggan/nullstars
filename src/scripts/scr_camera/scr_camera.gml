
/// @arg {asset.GMObject} _target
function game_camera_set_target(_target) {
	global.game.camera.target = _target;
}

function game_camera_get() {
	static __cam = {
		x: 0, y: 0, w: 0, h: 0
	};
	__cam.x = camera_get_view_x(view_camera[0]);
	__cam.y = camera_get_view_y(view_camera[0]);
	__cam.w = camera_get_view_width(view_camera[0]);
	__cam.h = camera_get_view_height(view_camera[0]);
	return __cam;
}

/// @arg {real} _shake
/// @arg {real} _damp
function game_camera_set_shake(_shake, _damp) {
	global.game.camera.shake_time = max(global.game.camera.shake_time, _shake);
	global.game.camera.shake_damp = _damp;
}

function Camera() constructor {
	
	target = obj_player;
	
	x = 0;
	y = 0;
	
	x_sod = new Sod().set_accuracy();
	y_sod = new Sod().set_accuracy();
	
	target_x = 0;
	target_y = 0;
	
	shake_time = 0;
	shake_damp = 1;
	
	/// @arg {struct.Game} _game
	static update = function (_game) {
		self.calculate(true);
	}
	
	/// @arg {bool} _anim
	static calculate = function (_anim) {
			
		var _cam_w = camera_get_view_width(view_camera[0]);
		var _cam_h = camera_get_view_height(view_camera[0]);
	
		if instance_exists(self.target) {
			static __out = {
				x: 0, y: 0,
			};
			__out.x = self.x;
			__out.y = self.y;
			self.target.cam(__out); // bandage
			self.target_x = __out.x;
			self.target_y = __out.y;
		}
	
		var _tx = self.target_x, _ty = self.target_y;
		var _ts = 0.025;
		
		with collision_point(_tx, _ty, obj_camera_focus, true, true) {
			var _dist = point_distance(_tx, _ty, x, y);
			_tx = lerp(_tx, x, max(0, 1 - power(_dist / sprite_width * 2, weight)));
			_ty = lerp(_ty, y, max(0, 1 - power(_dist / sprite_height * 2, weight)));
			if force {
				_tx = x;
				_ty = y;
			}
		}

		var _scale = 128;
		
		var _f = 420;
		var _final_tx = 0;
		var _final_ty = 0;
		
		var _k = 1;
		
		with obj_camera_room {
			var _d = sdf(
				_tx, _ty,
				x + crop_x1 * TILESIZE,
				y + crop_y1 * TILESIZE,
				x + sprite_width - crop_x2 * TILESIZE,
				y + sprite_height - crop_y2 * TILESIZE
			);
			
			var _d_s = _d / sqrt(_scale * 2);
			var _d_k = (_d - _scale) / _scale;
			
			var _s = weight;
			
			var _p = _s <= 0 ? hmin(_f, _d_s) : smin(_f, _d_s, _s);
			_f = _p[0];
			
			var _self_tx = _tx;
			if unlock_x {
				if sprite_width <= _cam_w {
					_self_tx = x + sprite_width / 2;
				} else {
					_self_tx = clamp(_tx, x + _cam_w / 2, x + sprite_width - _cam_w / 2);
				}
			}
			var _self_ty = _ty;
			if unlock_y {
				if sprite_height <= _cam_h {
					_self_ty = y + sprite_height / 2;
				} else {
					_self_ty = clamp(_ty, y + _cam_h / 2, y + sprite_height - _cam_h / 2);
				}
			}
			
			_final_tx = lerp(_final_tx, _self_tx, _p[1]);
			_final_ty = lerp(_final_ty, _self_ty, _p[1]);
			
			_k -= power(clamp(-_d_k, 0, 1), 2);
		}
		_k = max(_k, 0);
		
		_final_tx = lerp(_final_tx, _tx, _k);
		_final_ty = lerp(_final_ty, _ty, _k);
		
		_tx = _final_tx;
		_ty = _final_ty;
		
		if _anim {
			self.x_sod.set_weights(_ts, 1, 0.25);
			self.y_sod.set_weights(_ts, 1, 0.25);
			self.x_sod.update(_tx);
			self.y_sod.update(_ty);
	
			self.x = self.x_sod.get_value();
			self.y = self.y_sod.get_value();
		} else {
			self.x = _tx;
			self.y = _ty;
			self.x_sod.set_value(self.x);
			self.y_sod.set_value(self.y);
		}
		
		var _shake_dir = irandom_range(0, 360);
		var _shake_x = round(lengthdir_x(self.shake_time, _shake_dir));
		var _shake_y = round(lengthdir_y(self.shake_time, _shake_dir));
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
			floor(self.x - _cam_w / 2) + _shake_x, 
			floor(self.y - _cam_h / 2) + _shake_y
		);

	}
	
	log(Log.note, "Camera(): initialized");
}

