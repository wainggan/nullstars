

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

