
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

