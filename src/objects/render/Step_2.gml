
cache_time = global.game.state.timer_length - global.game.state.timer_current;
if !game_timer_running() {
	cache_time = 0;
}
cache_time_str = game_string_timer(cache_time);

