
function game_checkpoint_add(_object) {
	global.game.checkpoint.add(_object);
}

function game_checkpoint_set_index(_index) {
	global.game.checkpoint.set_index(_index);
	global.game.checkpoint.data(_index).collected = true;
	game_file_save();
}

function game_checkpoint_set_dyn(_x, _y) {
	global.game.checkpoint.set_dyn(_x, _y);
	// game_file_save();
}

/// @return {string}
function game_checkpoint_get_index() {
	return global.game.checkpoint.get_index();
}
function game_checkpoint_get_dyn() {
	return global.game.checkpoint.get_dyn();
}

function game_checkpoint_pos() {
	return global.game.checkpoint.pos();
}

function game_checkpoint_get_is_index() {
	return global.game.checkpoint.current_type == 0;
}
