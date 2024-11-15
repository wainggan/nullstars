
enum Log {
	hide,
	note,
	warn,
	error,
	user,
	none,
}

function Logger() constructor {
	
	point = Log.user;
	messages = [];
	anims = [];
	
	static write = function (_level, _message) {
		show_debug_message($"{_level} :: {_message}");
		if _level >= point {
			array_insert(messages, 0, _message);
			array_insert(anims, 0, 0);
		}
	}
	
	static update = function () {
		
		for (var i = 0; i < array_length(anims); i++) {
			anims[i] = approach(anims[i], 1, 1 / (60 * 6));
			if anims[i] == 1 {
				array_pop(messages);
				array_pop(anims);
			}
		}
		
	}
	
}

global.logger = new Logger();

function log(_level, _message) {
	global.logger.write(_level, _message);
}
function log_level(_level) {
	global.logger.point = _level;
}

