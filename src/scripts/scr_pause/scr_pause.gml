
function game_set_pause(_pause) {
	global.game.state.set_pause(_pause);
}

function game_set_freeze(_pause) {
	global.game.state.set_pause_freeze(_pause);
}

function game_paused() {
	return global.game.state.get_pause();
}

