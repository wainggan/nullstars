
function game_timer_start(_length, _target = undefined) {
	global.game.state.timer_start(_length, _target);
}

function game_timer_get() {
	return global.game.state.timer_get();
}

function game_timer_stop() {
	global.game.state.timer_stop();
}

function game_timer_running() {
	return global.game.state.timer_running();
}

// @todo: ??
function game_string_timer(_number) {
	var _seconds = floor(_number / 60);
	var _seconds_str = string(_seconds);
	
	var _milliseconds = floor((_number / 60 * 1000) % 1000);
	var _milliseconds_str = string(_milliseconds);
	
	while string_length(_milliseconds_str) < 3 _milliseconds_str += "0";
	
	var _str = $"{_seconds_str} . {_milliseconds_str}";
	
	return _str;
}
