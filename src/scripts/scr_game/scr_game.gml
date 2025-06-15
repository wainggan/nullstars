
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
	
	
	buffers = new GameBuffers();
	
	global.time = 0;
	state = new GameState();
	
	input = new Controls();
	camera = new Camera();
	
	checkpoint = new GameHandleCheckpoints();
	gate = new GameHandleGates();
	
	level = new Loader();
	
	schedule = new Schedule();
	
	news_sound = new News();
	
	menu = new GameMenu();
	
	music = new Music();
	
	
	timelines = [];
	
	/// @arg {struct.Timeline} _timeline
	static add_timeline = function (_timeline) {
		array_push(timelines, _timeline);
	};
	
	
	static update_begin = function() {
		global.logger.update();
		self.state.update();
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
		self.music.update();
		self.buffers.update();
	}
	
	static step_begin = function() {
		schedule.update();
	};
	static step = function() {
		
	};
	static step_end = function() {
		for (var i = 0; i < array_length(timelines); i++) {
			var _t = timelines[i];
			_t.tick();
			if _t.complete() {
				array_delete(timelines, i--, 1);
			}
		}
		
		camera.update(self);
		
		if !game_checkpoint_get_is_index() {
			var _dyn = game_checkpoint_get_dyn();
			if !instance_exists(obj_checkpoint_dyn) {
				instance_create_layer(_dyn.x, _dyn.y - 20, "Instances", obj_checkpoint_dyn);
			} else {
				obj_checkpoint_dyn.x = _dyn.x;
				obj_checkpoint_dyn.y = _dyn.y - 20;
			}
		} else {
			instance_destroy(obj_checkpoint_dyn);
		}
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
	
	add_timeline(
		new Timeline()
			.add(new KeyframeRespawn(true, true))
	);
	
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
	oo_updown = true;
	
	// timer state
	timer_active = false;
	timer_length = 0;
	timer_current = 0;
	timer_target = noone;
	
	
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
			if timer_length - timer_current < 0 {
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
		oo_updown = true;
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
	
	
	static timer_start = function (_length, _target = noone) {
		timer_current = 0;
		timer_length = _length;
		timer_target = _target;
		timer_active = true;
		
		self.reset();
		with obj_Entity {
			reset();
		}
	};
	
	static timer_stop = function () {
		timer_current = 0;
		timer_length = 0;
		timer_target = noone;
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
	
	// 0 | 1
	current_type = 0;
	// current_type == 0
	current = "intro-0";
	// current_type == 1
	current_x = 0;
	current_y = 0;
	
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
	};
	static get_index = function () {
		return current_type == 0 ? current : undefined;
	};
	static get_dyn = function () {
		static __out = {
			x: 0,
			y: 0,
		};
		__out.x = current_x;
		__out.y = current_y;
		return current_type == 1 ? __out : undefined;
	};
	static ref = function (_index) {
		return list[$ _index].object;
	};
	static data = function (_index) {
		return list[$ _index];
	};
	static set_index = function (_index) {
		current_type = 0;
		current = _index;
	};
	static set_dyn = function (_x, _y) {
		current_type = 1;
		current_x = _x;
		current_y = _y;
	};
	
	static pos = function () {
		static __out = {
			x: 0,
			y: 0,
		};
		if current_type == 0 {
			var _ref = self.ref(self.get_index());
			__out.x = _ref.x;
			__out.y = _ref.y;
		} else {
			ASSERT(current_type == 1);
			var _dyn = self.get_dyn();
			__out.x = _dyn.x;
			__out.y = _dyn.y;
		}
		return __out;
	};
	
}
function GameHandleGates() constructor {
	list = {};
	
	static unpack = function() {
		
		var _names = variable_struct_get_names(global.data.gates);
		for (var i = 0; i < array_length(_names); i++) {
			var _index = _names[i];
			
			if list[$ _index] == undefined {
				list[$ _index] = {};
			}
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
		data(_object.name);
	}

	static data = function(_index) {
		list[$ _index] ??= {
			complete: false,
			time: 0,
		};
		return list[$ _index];
	}
}

function GameMenu() constructor {
	system = new Menu();
	
	page_none = new MenuPageList()
	.add(new MenuButton(global.strings[$ "menu-i-close"], function(){
		system.close();
	}))
	.add(new MenuButton(global.strings[$ "menu-i-map"], function(){
		system.open(page_map);
	}))
	.add(new MenuButton(global.strings[$ "menu-i-setting"], function(){
		system.open(page_settings);
	}))
	.add(new MenuButton("char", function(){
		system.open(page_char);
	}))
	.add(new MenuButton(global.strings[$ "menu-i-debug"], function(){
		LOG(Log.warn, "good luck");
		system.open(page_debug);
	}))
	.add(new MenuButton(global.strings[$ "menu-i-exit"], function(){
		game_end();
	}));
	
	page_map = new MenuPageMap();
	
	page_char = new MenuPageList()
	.add(new MenuButton(global.strings[$ "menu-i-close"], function () {
		system.close();
	}))
	.add(new MenuButton("cloth", function () {
		system.open(page_char_cloth);
	}))
	.add(new MenuButton("accessory", function () {
		system.open(page_char_acc);
	}))
	.add(new MenuButton("ears", function () {
		system.open(page_char_ears);
	}))
	.add(new MenuButton("tail", function () {
		system.open(page_char_tail);
	}))
	.add(new MenuButton("color", function () {
		system.open(page_char_color);
	}));
	
	page_char_cloth = new MenuPageChar(0);
	page_char_acc = new MenuPageChar(1);
	page_char_ears = new MenuPageChar(2);
	page_char_tail = new MenuPageChar(3);
	page_char_color = new MenuPageChar(4);
	
	page_settings = new MenuPageList()
	.add(new MenuButton("back", function(){
		system.close();
	}))
	.add(new MenuButton("graphics", function(){
		system.open(page_settings_graphics);
	}))
	.add(new MenuButton("performance", function(){
		system.open(page_settings_performance);
	}))
	.add(new MenuButton("accessibility", function(){
		system.open(page_settings_accessibility);
	}))
	.add(new MenuButton("sound", function(){
		system.open(page_settings_sound);
	}));
	
	page_settings_graphics = new MenuPageList(260)
	.add(new MenuButton("back", function(){
		system.close();
	}))
	.add(new MenuRadio(global.strings[$ "menu_setting_graphic-i-winscale"], 
			["1x", "2x", "3x", "4x"],
			global.settings.graphic.windowscale,
			function(_) {
		global.settings.graphic.windowscale = _;
		game_update_windowscale(_ + 1);
		game_file_save();
	}, global.strings[$ "menu_setting_graphic-h-winscale"]))
	.add(new MenuRadio("fullscreen", 
			["off", "exclusive", "borderless"],
			global.settings.graphic.fullscreen,
			function(_) {
		global.settings.graphic.fullscreen = _;
		game_update_fullscreen(_);
		game_file_save();
	}, @"set the fullscreen.
	'exclusive' may run faster than 'borderless', though 'borderless' allows you to change windows easier."))
	.add(new MenuRadio("screen shake", 
			["none", "0.5x", "1x"],
			global.settings.graphic.screenshake,
			function(_) {
		global.settings.graphic.screenshake = _;
		game_file_save();
	}))
	.add(new MenuRadio("lights", 
			["none", "simple", "shadows"],
			global.settings.graphic.lights,
			function(_) {
		global.settings.graphic.lights = _;
		game_file_save();
	}, @"in weaker graphics cards, lights are the primary cause of performance issues.
	- 'shadows' enables all lights.
	- 'simple' keeps lights, but disables tile shadow casting. this is usually good enough.
	- 'none' disables lights entirely."))
	.add(new MenuRadio("reflections", 
			["off", "on"],
			global.settings.graphic.reflections,
			function(_) {
		global.settings.graphic.reflections = _;
		game_file_save();
	}, @"enables background and puddle reflections.
	disabling can save some performance in weaker graphics cards."))
	.add(new MenuRadio("bloom", 
			["off", "on"],
			global.settings.graphic.bloom,
			function(_) {
		global.settings.graphic.bloom = _;
		game_file_save();
	}, @"enables the bloom post processing layer.
	disabling can save some performance in weaker graphics cards."))
	.add(new MenuRadio("distortion", 
			["off", "on"],
			global.settings.graphic.distortion,
			function(_) {
		global.settings.graphic.distortion = _;
		game_file_save();
	}, @"enables the pixel distortion post processing layer.
	disabling can save a tiny bit of performance in weaker graphics cards."))
	.add(new MenuRadio("chromatic abberation", 
			["off", "on"],
			global.settings.graphic.abberation,
			function(_) {
		global.settings.graphic.abberation = _;
		game_file_save();
	}, @"enables a subtle immitation of chromatic abberation along the edges of the screen.
	disabling can save a tiny bit of performance in weaker graphics cards."))
	.add(new MenuRadio("screen cracks", 
			["off", "on"],
			global.settings.graphic.cracks,
			function(_) {
		global.settings.graphic.cracks = _;
		game_file_save();
	}, @"enables an effect that causes the edges of the screen to randomly offset.
	disabling can save a tiny bit of performance in weaker graphics cards."))
	.add(new MenuRadio("backgrounds", 
			["simplified", "0.5x", "full"],
			global.settings.graphic.backgrounds,
			function(_) {
		global.settings.graphic.backgrounds = _;
		game_file_save();
	}, @"in weaker graphics cards. shader based backgrounds can eat performance.
	- '0.5x' halves the resolution of shader based backgrounds.
	- 'simplified' replaces them with a static picture (+3mb ram)."))
	.add(new MenuRadio("text scale", 
			["1x", "2x"],
			global.settings.graphic.textscale,
			function(_) {
		global.settings.graphic.textscale = _;
		game_file_save();
	}, @"set the ui text scale to something larger if needed"))
	
	page_settings_performance = new MenuPageList()
	.add(new MenuButton("back", function(){
		system.close();
	}))
	.add(new MenuRadio("reduce saves", 
			["off", "on"],
			0,
			function(_) {
		game_file_save();
	}, @"normally, nullstars will save the game whenever you change checkpoint, complete a gate, change a setting, etc.
	this setting allows you to disable this, requiring you to manually save using the 'save' button."))
	.add(new MenuSlider("room loading threshold",
			16, 256, 16,
			0,
			function(_) {
		game_file_save();
	}, @"nullstars splits the map into several 'rooms'. when these are loaded, they can take quite a bit of cpu time.
	this setting configures how close to the camera view a room must be to be loaded. the smaller the setting, the closer to the camera the room has to be.
	smaller values may cause some stuttering in busy areas."))
	.add(new MenuSlider("file loading threshold",
			256, 1024, 64,
			0,
			function(_) {
		game_file_save();
	}, @"rooms are stored as seperate files. this saves ram, however, it does mean that if you get close to a completely unloaded room, the file will have to be read from your drive.
	that can be quite slow on systems with slower hard drives, and may cause short freezes.
	this setting configures how close to the camera view a room must be to be kept in memory."))
	.add(new MenuSlider("file loading timer",
			0, 40, 4,
			0,
			function(_) {
		game_file_save();
	}, @"this settings will set how long it takes (in seconds) for a room far enough away to be completely unloaded (as set in the previous setting) to be actually unloaded.
	longer times can reduce how often a file have to be loaded, though it does take more ram."))
	
	page_settings_accessibility = new MenuPageList()
	.add(new MenuButton("back", function(){
		system.close();
	}))
	.add(new MenuRadio("dashes", 
			["normal", "2x", "infinite"],
			0,
			function(_) {
		game_file_save();
	}, undefined))
	.add(new MenuRadio("invincibility", 
			["off", "on"],
			0,
			function(_) {
		game_file_save();
	}, undefined))
	.add(new MenuRadio("gate locks", 
			["off", "on"],
			0,
			function(_) {
		game_file_save();
	}, undefined))
	.add(new MenuRadio("gate terms", 
			["off", "on"],
			0,
			function(_) {
		game_file_save();
	}, undefined))
	
	
	page_settings_sound = new MenuPageList()
	.add(new MenuButton("back", function(){
		system.close();
	}))
	.add(new MenuSlider("mix", 0, 10, 1, global.settings.sound.mix, function(_) {
		global.settings.sound.mix = _;
		global.game.news_sound.push(undefined);
		game_file_save();
	}))
	.add(new MenuSlider("bgm", 0, 10, 1, global.settings.sound.bgm, function(_) {
		global.settings.sound.bgm = _;
		global.game.news_sound.push(undefined);
		game_file_save();
	}))
	.add(new MenuSlider("sfx", 0, 10, 1, global.settings.sound.sfx, function(_) {
		global.settings.sound.sfx = _;
		global.game.news_sound.push(undefined);
		game_file_save();
	}))
	
	page_debug = new MenuPageList()
	.add(new MenuButton("back", function(){
		system.close();
	}))
	.add(new MenuButton("clear save data", function(){
		file_delete(FILE_DATA);
		game_end(0);
	}, @"immediately delete the save file and close the game."))
	.add(new MenuButton("gc", function(){
		var _stats = gc_get_stats();
		var _text = $"{_stats}";
		LOG(Log.note, _text);
		gc_collect();
	}, @"force run the gc."))
	.add(new MenuRadio("gc time", 
			["100ns", "500ns", "1000ns"],
			global.settings.debug.gctime,
			function(_) {
		global.settings.debug.gctime = _;
		game_update_gctime(global.settings.debug.gctime);
		game_file_save();
	}, @"set the gc's target time. may help with stuttering."))
	.add(new MenuRadio("overlay", 
			["off", "on"],
			global.settings.debug.overlay,
			function(_) {
		global.settings.debug.overlay = _;
		game_update_overlay(global.settings.debug.overlay);
		game_file_save();
	}, @"enable gamemaker's debug overlay."))
	.add(new MenuRadio("log", 
			["note", "warn", "error", "user"],
			global.settings.debug.log,
			function(_) {
		global.settings.debug.log = _;
		LOG(Log.user, $"log level set to {_}")
		game_update_log(global.settings.debug.log);
		game_file_save();
	}));
}

function GameBuffers() constructor {
	// [Buffer.Id, Real]
	// [0] - the buffer we cache
	// [1] - how many depend on it
	bins = {};
	bin_top = 0;
	
	static _Buffer = function (_parent, _id) constructor {
		parent = _parent;
		id = _id;
		
		static valid = function () {
			return parent.bins[$ id][1] > 0;
		};
		
		static bin = function () {
			ASSERT(valid());
			return parent.bins[$ id][0];
		};
		
		static push = function () {
			parent.bins[$ id][1] += 1;
			return self;
		};
		
		static pop = function () {
			parent.bins[$ id][1] -= 1;
			return self;
		};
	};
	
	static add = function (_buffer) {
		ASSERT(buffer_exists(_buffer));
		var _bin_id = bin_top++;
		bins[$ _bin_id] = [_buffer, 1];
		LOG(Log.note, $"GameBuffers(): created buffer id={_bin_id}");
		return new _Buffer(self, _bin_id);
	};
	
	static update = function () {
		var _bin_ids = struct_get_names(bins);
		for (var i = 0; i < array_length(_bin_ids); i++) {
			var _b = bins[$ _bin_ids[i]];
			if _b[1] <= 0 {
				buffer_delete(_b[0]);
				struct_remove(bins, _bin_ids[i]);
				LOG(Log.note, $"GameBuffers(): deleted buffer id={_bin_ids[i]}");
			}
		}
	};
}

