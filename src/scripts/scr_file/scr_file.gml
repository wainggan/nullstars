
global.version = {
	major: 0,
	minor: 0,
	patch: 0,
};

#macro FILE_DATA "save.star"
#macro FILE_INPUT "input.ini"

#macro FILE_DATA_VERSION 5

global.file = undefined;
global.settings = undefined;
global.data = undefined;

global.file_default = {
	
	"version": { // game version, used for nothing
		"major": 0,
		"minor": 0,
		"patch": 0,
	},
	"json": FILE_DATA_VERSION, // json version, used for updating
	
	"data": {
		
		/*
		flags
		*/
		"flags": {},
		
		"location": "intro-0",
		/*
		checkpoints
		"index": {}
			collected = has collected
			deaths = amount of respawns
		*/
		"checkpoints": {},
		
		/*
		stats
		deaths = total amount of deaths
		*/
		"stats": {
			"deaths": 0,
		},
		
		/*
		gates
		"name": {}
			complete = has complete
			time = best time in ms
		*/
		"gates": {},
		
		/*
		player stuff
		@todo: move to global file
		*/
		"player": {
			"cloth": 0,
			"accessory": 0,
			"ears": 0,
			"tail": 0,
			"color": 0,
		},
	
	},
	"settings": {
		"graphic": {
			"windowscale": 0,
				// 0 = 1x
				// 1 = 2x
				// 2 = 3x
				// 3 = 4x
			"textscale": 0,
				// 0 = 1x
				// 1 = 2x
			"fullscreen": 0,
				// 0 = off
				// 1 = exclusive
				// 2 = borderless
			"screenshake": 2,
				// 0 = none
				// 1 = 0.5x
				// 2 = 1x
			"lights": 2,
				// 0 = off
				// 1 = rimblur + spotlights
				// 2 = shadows
			"reflections": 1,
				// 0 = off
				// 1 = on
			"backgrounds": 1,
				// 0 = simplified
				// 1 = full
			"bloom": 1,
				// 0 = off
				// 1 = on
				// 2 = extreme
			"distortion": 1,
				// 0 = off
				// 1 = 1/4x
				// 2 = 1/2x
			"abberation": 1,
				// 0 = off
				// 1 = on
				// 2 = extreme
			"cracks": 1,
				// 0 = off
				// 1 = on
				// 2 = extreme
		},
		"sound": {
			"bgm": 8,
			"sfx": 10,
			"mix": 10,
		},
		"debug": {
			"gctime": 2,
				// 0 = 100
				// 1 = 500
				// 2 = 1000
				// 3 = 2000
			"overlay": 0,
				// 0 = off
				// 1 = on
			"speed": 2,
				// 0 = 10fps
				// 1 = 30fps
				// 2 = 60fps
			"log": 3,
				// 0 = note
				// 1 = error
				// 2 = warn
				// 3 = note
		},
	},
};

function game_file_upgrade(_file) {
	// todo: very temporary
	if _file.json < FILE_DATA_VERSION {
		LOG(Log.user, $"update system not implemented, falling back to empty file!");
		LOG(Log.user, $"really sorry about this. make parchii fix this.");
		_file = json_parse(json_stringify(global.file_default));
	}
	var i = _file.json;
	for (; i < FILE_DATA_VERSION; i++) {
		LOG(Log.user, $"updating save file from {_file.json} to {i}...");
	}
	return _file;
}

// todo: move to Game()
function game_file_save() {
	global.game.pack();
	game_json_save(FILE_DATA, global.file);
}

/// writes to a file
/// @arg {string} _filename
function game_json_save(_filename, _tree) {
	LOG(Log.hide, $"util_json_save: writing file {_filename}");
	
	var _string = json_stringify(_tree, true);
	var _buffer = buffer_create(string_byte_length(_string) + 1, buffer_fixed, 1);
	
	buffer_write(_buffer, buffer_string, _string);
	buffer_save(_buffer, _filename);
	buffer_delete(_buffer);
}

/// opens a json file.
/// 
/// returns `-1` if an error occured.
/// @arg {string} _filename
/// @return {struct | real}
function game_json_open(_filename) {
	if !file_exists(_filename) {
		LOG(Log.error, $"util_json_open: file {_filename} doesn't exist!");
		return -1;
	}
	
	LOG(Log.note, $"util_json_open: loading file {_filename}");
	
	var _buffer = buffer_load(_filename);
	var _string = buffer_read(_buffer, buffer_string);
	buffer_delete(_buffer);
	
	var _data = json_parse(_string, undefined, true);
	
	// kill me
	// Feather ignore once GM1045
	return _data;
}

