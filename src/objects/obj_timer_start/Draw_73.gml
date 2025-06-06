

if anim_running < 1 {
	for (var i = 0; i < 3; i++) {
		var _san = (global.time + (240 / 3) * i) % 240 / 240 * 2 - 1;
		var _dir = anim_dir * 90;
		var _mag = (1 - tween(Tween.Ease, 1 - abs(_san))) * sign(_san) * 48;
		var _sc = hermite(min(2 * (1 - abs(_san)), 1) * (1 - anim_running));
		draw_sprite_ext(
			spr_timer_arrow, 0,
			(bbox_left + bbox_right) / 2 + lengthdir_x(_mag, _dir),
			(bbox_top + bbox_bottom) / 2 + lengthdir_y(_mag, _dir),
			_sc, _sc,
			_dir, c_white, 1
		);
	}
}
if anim_running > 0 {
	var _sc = 0.4 * game_music_get_beat_lead();
	draw_sprite_ext(
		spr_timer_arrow, 1,
		(bbox_left + bbox_right) / 2,
		(bbox_top + bbox_bottom) / 2,
		(1 + _sc) * anim_running, (1 + _sc) * anim_running,
		0, c_white, 1
	);
}

with level_get_instance(ref) {
	if other.anim_running > 0 || other.anim_pop {
		var _amount = 7;
		for (var i = 0; i < _amount; i++) {
			var _p0_x = x + lerp(0, sprite_width, i / _amount);
			var _p0_y = y + lerp(0, sprite_height, i / _amount);
			
			var _d = wave(0, 4, 10, i * 0.7135) + global.time / 60 / 4;
			var _s = wave(0, 1, 8, i * 0.7135);
			
			var _p1_x = (bbox_left + bbox_right) / 2 + cos(_d) * (32 + _s * 32);
			var _p1_y = (bbox_top + bbox_bottom) / 2 + sin(_d) * (32 + _s * 32);
			
			var _p_x = round(herp(_p0_x, _p1_x, other.anim_running));
			var _p_y = round(herp(_p0_y, _p1_y, other.anim_running))
			var _p_s = round_ext(power(other.anim_running, 2) * (8 + _s * 16), 2);
			
			if other.anim_pop {
				game_render_particle_ambient(_p1_x, _p1_y, ps_timer_pop);
			} else if !other.anim_is_complete {
				draw_circle_sprite(_p_x, _p_y, _p_s, c_white, 1);
			} else {
				draw_circle_outline(_p_x, _p_y, _p_s * 0.5, 2, c_white, 1, 11);
			}
		}
		if other.anim_pop {
			other.anim_pop = false;
		}
	}
	
	draw_sprite_ext(
		spr_timer_end_wall, 0,
		x, y,
		image_xscale, image_yscale,
		0, c_white, 1 - other.anim_wall
	);
}

