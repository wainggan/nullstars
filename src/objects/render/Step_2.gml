
if game_timer_running() {
	anim_time = approach(anim_time, 1, 0.1);
	anim_time_stop = 0;
	
	cache_time = global.game.state.timer_length - global.game.state.timer_current;
} else {
	// cache_time = 0;
	
	anim_time_stop = approach(anim_time_stop, 1, 1 / 120);
	
	if anim_time_stop >= 1 {
		anim_time = approach(anim_time, 0, 0.02);
	}
}

cache_time_str = game_string_timer(cache_time);

