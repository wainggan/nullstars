/*
logging syste,.

unfortunately, this logging system is both used for debugging, and occasional
user-level messages. hence why `Log.User` exists. very sad.
*/

#macro ENABLE_LOG true

enum Log {
	Hide,
	Note,
	Warn,
	Error,
	User,
	None,
}

function Logger() constructor {
	point = Log.User;
	messages := [];
	anims := [];
	
	static write = function (_level, _message, _file, _line) {
		show_debug_message($"{_level} @ {_file}:{_line} :: {_message}");

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

function log_level(_level) {
	global.logger.point = _level;
}

/// @ignore
function __log__(_file, _line) {
    static __ctx = {
        file: "",
        line: "",
    };

    static __out = method(__ctx, function (_level, _message) {
		global.__logger.write(_level, _message, file, line);
    });

    __ctx.file = _file;
    __ctx.line = _line;
    
    return __out;
}

global.__logger = new Logger();

LOG(Log.Note, "init");

#macro LOG if !ENABLE_LOG {} else __log__(_GMFILE_, _GMLINE_)

