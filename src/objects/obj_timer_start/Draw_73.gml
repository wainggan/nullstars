
with level_get_instance(ref) {
	if other.anim_running > 0 || other.anim_pop {
		var _amount = 8;
		for (var i = 0; i < _amount; i++) {
			var _p0_x = x + lerp(0, sprite_width, i / _amount);
			var _p0_y = y + lerp(0, sprite_height, i / _amount);
			
			var _d = wave(0, 4, 10, i * 0.7135) + global.time / 60 / 4;
			var _s = wave(0, 1, 8, i * 0.7135);
			
			var _p1_x = (bbox_left + bbox_right) / 2 + cos(_d) * (32 + _s * 32);
			var _p1_y = (bbox_top + bbox_bottom) / 2 + sin(_d) * (32 + _s * 32);
			
			var _p_x = herp(_p0_x, _p1_x, other.anim_running);
			var _p_y = herp(_p0_y, _p1_y, other.anim_running);
			
			if other.anim_pop {
				game_render_particle(_p1_x, _p1_y, ps_timer_pop);
			} else if !other.anim_is_complete {
				draw_circle_sprite(_p_x, _p_y, power(other.anim_running, 2) * (8 + _s * 16), c_white, 1);
			} else {
				draw_circle_outline(_p_x, _p_y, power(other.anim_running, 2) * (8 + _s * 16) * 0.5, 2, c_white, 1, 12);
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

