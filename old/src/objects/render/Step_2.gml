
if game_timer_running() {
	anim_time = approach(anim_time, 1, 0.1);
	anim_time_main = approach(anim_time_main, 1, 0.15);
	anim_time_close = approach(anim_time_close, 0, 0.15);
	anim_time_stop = 0;
	
	if instance_exists(global.game.state.timer_target) {
		var _inst = level_get_instance(global.game.state.timer_target.ref);
		
		ASSERT(instance_exists(_inst));

		anim_target_x = _inst.x;
		anim_target_y = _inst.y;
		anim_target_w = _inst.sprite_width;
		anim_target_h = _inst.sprite_height;
	} else {
		anim_target_w = 0;
		anim_target_h = 0;
	}
	
	cache_time = global.game.state.timer_length - global.game.state.timer_current;
	cache_elapse = global.game.state.timer_current;
} else {
	// cache_time = 0;
	
	anim_time_stop = approach(anim_time_stop, 1, 1 / 120);
	
	if anim_time_stop >= 1 {
		anim_time = approach(anim_time, 0, 0.04);
		anim_time_main = approach(anim_time_main, 0, 0.02);
	}
	
	if anim_time_main == 0 {
		anim_time_close = 0;
	} else {
		anim_time_close = approach(anim_time_close, 1, 0.15);
	}
}

cache_time_str = game_string_timer(cache_time);
cache_elapse_str = game_string_timer(cache_elapse);

