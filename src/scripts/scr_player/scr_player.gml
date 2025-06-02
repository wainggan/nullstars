

function game_player_kill() {
	if !instance_exists(obj_player) {
		return;
	}
	
	var _x = obj_player.x, _y = obj_player.y;
	
	game_render_particle(_x, _y - 16, ps_player_death_0);
	
	game_sound_play(sfx_death);
	
	game_set_pause(14);
	game_camera_set_shake(2, 0.4);
	
	game_timer_stop();
	
	instance_destroy(obj_player);
	
	global.game.add_timeline(
		new Timeline()
			.add(new KeyframeTimed(2))
			.add(new KeyframeCallback(method({ _x, _y }, function(){
				game_render_particle(_x, _y - 16, ps_player_death_1);
				game_camera_set_shake(8, 0.8);
				game_set_pause(1);
				game_render_wave(_x, _y - 16, 256, 90, 1, spr_wave_wave);
				
				with obj_Entity {
					reset();
				}
				global.onoff = 1;
			})))
			.add(new KeyframeTimed(10))
			.add(new KeyframeRespawn().set_pos(_x, _y))
	);
}

enum PlayerFrame {
	stand = 0,
	walk_1a = 3,
	walk_1b = 4,
	walk_2a = 1,
	walk_2b = 2,
	jump = 5,
	fall = 6,
	dive = 7,
	dash = 9,
	long = 8,
	swim_idle_1 = 11,
	swim_idle_2 = 12,
	swim_1 = 13,
	swim_2 = 14,
	swim_bullet = -1,
	ledge = 16,
	crouch = 17,
	flip_1 = 18,
	flip_2 = 19,
	run_1 = 21,
	run_2 = 22,
	run_3 = 23,
	run_jump = 21,
	run_fall = 24,
}

enum PlayerCharTail {
	normal = 0,
	hooked = 1,
	halo = 2,
	dots = 3,
	// . . . .
	//       | . . . . . . . .
	//       | . . . . . . . .
	fork = 4,
	geared = 5,
}

/// draw the player.
/// @arg {real} _frame frame of the player to draw. use `-1` for swim_bullet
/// @arg {real} _x
/// @arg {real} _y
/// @arg {real} _x_scale
/// @arg {real} _y_scale
/// @arg {real} _angle only used for swim_bullet
/// @arg {constant.Color} _blend
/// @arg {string} _cloth
/// @arg {string} _accessory
function draw_player(_frame, _x, _y, _x_scale, _y_scale, _angle, _blend, _cloth = "none", _accessory = "none") {
	if _frame == PlayerFrame.swim_bullet {
		draw_sprite_ext(
			spr_player_bullet,
			_frame, _x, _y,
			_x_scale, _y_scale,
			_angle, _blend, 1
		);
		return;
	}
	
	draw_sprite_ext(
		spr_player,
		_frame, _x, _y,
		_x_scale, _y_scale,
		_angle, _blend, 1
	);
	
	var _check;
	_check = global.data_char[$ _cloth];
	if _check != undefined {
		draw_sprite_ext(
			_check,
			_frame, _x, _y,
			_x_scale, _y_scale,
			_angle, _blend, 1
		);
	}
	
	_check = global.data_char[$ _accessory];
	if _check != undefined {
		draw_sprite_ext(
			_check,
			_frame, _x, _y,
			_x_scale, _y_scale,
			_angle, _blend, 1
		);
	}
}

/// manages the player's tail
function PlayerTail() constructor {
	points = [];
	repeat 30 {
		array_push(points, new Yarn());
	}
	
	friend_x = 0;
	friend_y = 0;
	
	static get_len = function (_mode) {
		if _mode == PlayerCharTail.dots {
			return 11;
		}
		if _mode == PlayerCharTail.fork {
			return 20;
		}
		if _mode == PlayerCharTail.geared {
			return 14;
		}
		return 12;
	};
	
	// _state == 0 : normal
	// _state == 1 : swim_bullet
	static update = function (_x, _y, _dir, _state, _mode) {
		ASSERT(0 <= _state && _state <= 1);
		
		points[0].x = _x;
		points[0].y = _y;
		points[0].update(, _dir == -1 ? 180 : 0, 1);
		
		var _len = get_len(_mode);
		
		for (var i = 1; i < min(array_length(points), _len); i++) {
			var _local_i = i;
			if _mode = PlayerCharTail.fork && i > 12 {
				_local_i -= 8;
			}
			
			var _scale_nor = (_local_i / _len);
			var _scale_inv = (_len - _local_i) / _len;
			
			var _x_move = 0;
			var _y_move = 0;
			var _length = 4;
			var _weight = 1;
			var _damp = 0.8;
			var _leeway = 0;
			
			if _mode = PlayerCharTail.dots {
				_length = 3 + _scale_nor * 7;
				_leeway = _scale_nor * 0.6;
			}
			
			if _state == 0 {
				var _offset = i * 0.6;
				if _mode = PlayerCharTail.fork {
					_offset = i * 0.5;
				}
				
				var _d = sin(global.time / 60 - _offset);
				_x_move = -_dir * (power(_scale_inv, 6) * 6 + 0.1);
				_y_move = _d * (_scale_inv * 0.2 + 0.1) + 0.3 * _scale_inv;
				
				if _mode = PlayerCharTail.fork && i > 12 {
					_y_move *= 1.1;
				}
			} else if _state == 1 {
				_damp = 0.5;
			}
			
			var _last_i = i - 1;
			if _mode = PlayerCharTail.fork && i > 12 {
				if i == 13 {
					_last_i = 4;
				}
			}
			
			points[i].update(points[_last_i], , _length, _x_move, _y_move, _weight, _damp, _leeway);
		}
		
		if _mode == PlayerCharTail.hooked {
			var _p = points[_len - 1];
			var _d_x = _p.x - lengthdir_x(6, _p.direction);
			var _d_y = _p.y - lengthdir_y(6, _p.direction);
			friend_x = lerp(friend_x, _d_x, 0.2);
			friend_y = lerp(friend_y, _d_y, 0.2);
		} else if _mode == PlayerCharTail.halo {
			var _p = points[9];
			friend_x = lerp(friend_x, _p.x, 0.4);
			friend_y = lerp(friend_y, _p.y, 0.4);
		}
	};
	
	static draw = function (_dash, _mode, _blend = c_white) {
		var _len = get_len(_mode);
		
		var _dash_0 = #00ffff;
		var _dash_1 = #ff00ff;
		var _dash_current = _dash == 0 ? _dash_0 : _dash_1;
		
		if _mode == PlayerCharTail.halo {
			var _p = points[9];
			draw_sprite_ext(
				spr_player_tail, 2, 
				round_ext(friend_x, 2), round_ext(friend_y, 2),
				10 / 16, 16 / 16, 
				round_ext(_p.direction, 5), c_white, 1
			);
		}
		
		for (var i = min(array_length(points), _len) - 1; i >= 0; i--) {
			var _local_i = i;
			var _local_len = _len;
			if _mode = PlayerCharTail.fork {
				if i > 12 {
					_local_i -= 8;
				}
				_local_len = 12;
			}
			
			var _c = merge_color(c_white, _dash_current, clamp(_local_i - 3, 0, _local_len) / _local_len);
			_c = multiply_color(_c, _blend);
			
			var _size = 8;
			_size = max(parabola_mid(3, 7, 6, _local_i) + 3, 6);
			
			var _round = floor(clamp(_local_i / (_local_len / 3), 1, 1));
			
			var _p = points[i];
			
			var _frame = 0;
			var _angle = 0;
			if _local_i == _local_len - 1 {
				if _mode == PlayerCharTail.hooked {
					_frame = 1;
					_angle = _p.direction;
					_size = 10;
				} else if _mode == PlayerCharTail.halo {
					_frame = 4;
					_angle = _p.direction;
					_size = 9;
				}
			}
			
			draw_sprite_ext(
				spr_player_tail, _frame, 
				round_ext(_p.x, _round), round_ext(_p.y, _round), 
				//round_ext(_p.x, 0), round_ext(_p.y, 0), 
				_size / 16, _size / 16, 
				round_ext(_angle, 5), _c, 1
			);
			
			if _mode == PlayerCharTail.geared && _local_i % 3 == 0 {
				draw_sprite_ext(
					spr_player_tail, 0, 
					round_ext(_p.x, _round), round_ext(_p.y, _round), 
					//round_ext(_p.x, 0), round_ext(_p.y, 0), 
					4 / 16, 16 / 16, 
					round_ext(_p.direction, 5), _c, 1
				);
			}
		}
		
		if _mode == PlayerCharTail.halo {
			var _p = points[9];
			draw_sprite_ext(
				spr_player_tail, 3, 
				round_ext(friend_x, 2), round_ext(friend_y, 2),
				10 / 16, 16 / 16,
				round_ext(_p.direction, 5), c_white, 1
			);
		} else if _mode == PlayerCharTail.hooked {
			draw_sprite_ext(
				spr_player_tail, 0, 
				round_ext(friend_x, 1), round_ext(friend_y, 1),
				4 / 16, 4 / 16,
				0, c_white, 1
			);
		}
	};
}

