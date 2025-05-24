
#macro INPUT global.game.input.manager

function Game() constructor {
	
	global.game = self;
	
	if !file_exists(FILE_DATA) {
		global.file = json_parse(json_stringify(global.file_default));
	} else {
		var _file = game_json_open(FILE_DATA);
		ASSERT(_file != -1);
		LOG(Log.note, "Game(): opened file json");
		_file = game_file_upgrade(_file);
		global.file = _file;
	}
	
	global.settings = global.file.settings; // alias
	global.data = global.file.data; // alias
	
	global.strings = game_json_open("strings.json");
	ASSERT(global.strings != -1);
	LOG(Log.note, "Game(): loaded strings.json");
	
	
	// @todo: temp
	global.onoff = 1;
	game_update_overlay(global.settings.debug.overlay);
	game_update_gctime(global.settings.debug.gctime);
	game_update_log(global.settings.debug.log);
	
	
	global.time = 0;
	state = new GameState();
	
	input = new Controls();
	camera = new Camera();
	
	checkpoint = new GameHandleCheckpoints();
	gate = new GameHandleGates();
	
	level = new Loader();
	
	schedule = new Schedule();
	
	news_sound = new News();
	
	
	static update_begin = function() {
		global.logger.update();
		input.update();
		
		if !self.state.get_pause() {
			self.step_begin();
		}
	};
	static update = function() {
		
		if !self.state.get_pause() {
			self.step();
		}
	};
	static update_end = function() {
		if !self.state.get_pause() {
			self.step_end();
		}
		
		self.level.update();
		self.state.update();
	}
	
	static step_begin = function() {
		schedule.update();
	};
	static step = function() {
		
	};
	static step_end = function() {
		camera.update(self);
	};
	
	static unpack = function() {
		LOG(Log.note, "Game(): running unpack()");
		
		checkpoint.unpack();
		gate.unpack();
	};
	static pack = function() {
		LOG(Log.note, "Game(): running pack()");
		
		checkpoint.pack();
		gate.pack();
	};
	
	level.setup();
	unpack();
	
	// instance_create_layer(0, 0, "Instances", obj_cutscene_respawn);
	
	LOG(Log.user, $"running nullstars! build {date_datetime_string(GM_build_date)} {GM_build_type} - {GM_version}");
}

function GameState() constructor {
	
	// frames since game start
	time = 0;
	
	/// freeze frames. decremented every frame
	pause = 0;
	pause_defer = 0;
	
	/// whether game objects should run at all
	pause_freeze = false;
	pause_freeze_defer = false;
	
	// on/off switches
	oo_onoff = true;
	oo_flipflop = true;
	
	// timer state
	timer_active = false;
	timer_length = 0;
	timer_current = 0;
	timer_target = 0;
	
	
	static update = function () {
		// update pause
		pause = pause_defer;
		pause -= 1;
		pause_defer = pause;
		
		pause_freeze = pause_freeze_defer;
		pause_freeze_defer = false;
		
		// update timer
		if timer_active {
			timer_current += 1;
			if timer_length - timer_current <= 0 {
				self.timer_stop();
			}
		}
		
		if !self.get_pause() {
			time += 1;
		}
		global.time = time;
	};
	
	static reset = function () {
		oo_onoff = true;
		oo_flipflop = true;
	};
	
	// game_get_pause() and game_pause() only change once game_pause_update() is run
	static set_pause = function (_frames) {
		// + 1 to make sure the first frame paused is preserved after update
		pause_defer = max(_frames + 1, pause_defer);
	};
	static set_pause_freeze = function (_freeze) {
		pause_freeze_defer = _freeze;
	};
	
	static get_pause = function () {
		return pause_freeze || pause > 0;
	};
	
	
	static timer_start = function (_length, _target = undefined) {
		timer_current = 0;
		timer_length = _length;
		timer_target = _target;
		timer_active = true;
		
		self.reset();
		with obj_Entity {
			reset();
		}
		
		instance_create_layer(0, 0, "Instances", obj_timer_render);
	};
	
	static timer_stop = function () {
		timer_current = 0;
		timer_active = false;
	};
	
	static timer_get = function () {
		return timer_current;
	};
	
	static timer_running = function () {
		return timer_active;
	};
	
}

function GameHandleCheckpoints() constructor {
	list = {};
	current = "intro-0";
	
	static unpack = function() {
		current = global.data.location;
		
		var _names = variable_struct_get_names(global.data.checkpoints);
		for (var i = 0; i < array_length(_names); i++) {
			var _index = _names[i];
			
			list[$ _index].collected = global.data.checkpoints[$ _index].collected;
			list[$ _index].deaths = global.data.checkpoints[$ _index].deaths;
			
		}
	}
	static pack = function() {
		global.data.location = current;
		
		var _names = variable_struct_get_names(list);
		for (var i = 0; i < array_length(_names); i++) {
			var _index = _names[i];
			
			if list[$ _index].collected {
				if global.data.checkpoints[$ _index] == undefined {
					global.data.checkpoints[$ _index] = {};
				}
				global.data.checkpoints[$ _index].collected = true;
				global.data.checkpoints[$ _index].deaths = list[$ _index].deaths;
			}
		}
		
	}
	
	static add = function(_object) {
		if list[$ _object.index] != undefined {
			LOG(Log.error, $"checkpoint: {_object.index} already exists!");
		}
		list[$ _object.index] = {
			object: _object,
			collected: false,
			deaths: 0,
		};
	}
	static get = function() {
		return current;
	}
	static ref = function(_index) {
		return list[$ _index].object;
	}
	static data = function(_index) {
		return list[$ _index];
	}
	static set = function(_index) {
		current = _index;
	}
	
}
function GameHandleGates() constructor {
	list = {};
	
	static unpack = function() {
		
		var _names = variable_struct_get_names(global.data.gates);
		for (var i = 0; i < array_length(_names); i++) {
			var _index = _names[i];
			
			list[$ _index].complete = global.data.gates[$ _index].complete;
			list[$ _index].time = global.data.gates[$ _index].time;
		}
		
	}
	static pack = function() {
		
		var _names = variable_struct_get_names(list);
		for (var i = 0; i < array_length(_names); i++) {
			var _index = _names[i];
			
			if list[$ _index].complete {
				if global.data.gates[$ _index] == undefined {
					global.data.gates[$ _index] = {};
				}
				global.data.gates[$ _index].complete = true;
				global.data.gates[$ _index].time = list[$ _index].time;
			}
		}
		
	}
	
	static add = function(_object) {
		if _object.name = "" {
			LOG(Log.error, $"gate: name is blank! {_object.x} {_object.y} {_object}")
		}
		if list[$ _object.name] != undefined {
			LOG(Log.warn, $"gate: {_object.name} already exists!");
		}
		list[$ _object.name] = {
			object: _object,
			complete: false,
			time: 0,
		};
	}

	static ref = function(_index) {
		return list[$ _index].object;
	}
	static data = function(_index) {
		return list[$ _index];
	}
}

