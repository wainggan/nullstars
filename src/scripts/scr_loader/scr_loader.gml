
/*
 * so here's the situation.
 * 
 * - rooms exist in the world
 * - when a room enters the "preparation zone", a "file"
 * command (called options below) is generated. this loads
 * a file into a buffer. the room is now "prepping"
 * - on completion, that generates a "parse" command. this
 * gets the information from the buffer
 * - when collisions and entities are collected, the room is
 * now "prepared".
 * - when a room enters the "loading zone", either a "file"
 * command is generated (if the level is "out"), or a "load"
 * command is generated. this creates the room's entities.
 * - this will check if the room is prepared/prepping. if
 * neither are true, then the "file" command is generated.
 * - once the room is prepared, we load the entities.
 * - when a room exits the loading zone, the room is demoted
 * to "prepared", and the entities it had can be destroyed.
 * - when a room exits the preparation zone, a "destroy"
 * command is created, which will destroy the room's resources.
 * 
 * this is a very delicate process with lots of room for
 * error. pay attention to `ASSERT()` where used.
 */


enum LoaderProgress {
	out,
	prepping,
	prepared,
	loaded,
}

/// responsible for all level loading related operations
function Loader() constructor {
	
	var _buffer = buffer_load("world/world.bin");
	if _buffer == -1 {
		LOG(Log.error, $"Loader(): file 'world.bin' doesn't exist");
		LOG(Log.error, "what do you even do about this?");
		ASSERT(false);
	}
	file = level_unpack_bin_main(_buffer);
	buffer_delete(_buffer);
	
	
	levels = array_create(array_length(file.rooms));
	
	for (var i = 0; i < array_length(levels); i++) {
		var _room = file.rooms[i];
		levels[i] = {
			id: i,
			loaded: LoaderProgress.out,
			time_load: 0,
			time_prep: 0,
			x: _room.x,
			y: _room.y,
			width: _room.width,
			height: _room.height,
			name: $"world/room/{_room.name}.bin",
			data: undefined,
		};
	}
	
	loaded = [];
	
	// [Buffer.Id, Real]
	// [0] - the buffer we cache
	// [1] - how many depend on it
	bins = {};
	bin_top = 0;
	
	queue = [];
	
	static queue_process = function () {
		static __sort = function (_a, _b) {
			return _b.priority - _a.priority;
		};
		array_sort(queue, __sort);
		
		var _todo = array_create(array_length(queue));
		for (var i = 0; i < array_length(_todo); i++) {
			_todo[i] = i;
		}
		
		var _remove = [];
		
		var _cam = game_camera_get();
		
		var _budget_runs = GAME_LOAD_BUDGET_COUNT;
		var _budget_time = GAME_LOAD_BUDGET_TIME; // ms
		
		while array_length(_todo) != 0 {
			var _time = get_timer();
			
			var _index = array_pop(_todo);
			var _item = queue[_index];
			
			var _status = LoaderOptionStatus.running;
			
			if _item.priority == 0 && util_check_level_zone_load(_cam, _item.level) {
				
				// this item must be processed now
				// keep processing it until it is complete
				while true {
					_status = _item.process(self);
					ASSERT(_status != undefined);
					
					if _status == LoaderOptionStatus.complete {
						break;
					}
					if _status == LoaderOptionStatus.wait {
						break;
					}
				}
				
				// if it must wait for the next frame to
				// be processed, freeze the game for a frame.
				if _status == LoaderOptionStatus.wait {
					game_set_freeze(true);
					continue;
				}
				
			} else if _budget_runs > 0 && _budget_time > 0 {
				// this item can be processed over multiple frames.
				_status = _item.process(self);
				ASSERT(_status != undefined);
				
				if _status != LoaderOptionStatus.complete {
					// whatever
					continue;
				}
			} else {
				continue;
			}
			
			ASSERT(_status == LoaderOptionStatus.complete);
			
			var _out = _item.collect(self);
			
			ASSERT(is_array(_out));
			
			for (var i = 0; i < array_length(_out); i++) {
				ASSERT(is_instanceof(_out[i], LoaderOption));
				
				// if we recieve a loaderoption, we need to add it to
				// the queue *and* todo list. this ensures that if it turns
				// out to be a priority 0 option, it gets dealt with correctly later
				array_push(queue, _out[i]);
				array_push(_todo, array_length(queue) - 1);
				// todo: sort?
			}
			
			// the item was complete, so remove it
			array_push(_remove, _index);
			
			// deal with budget
			_budget_runs -= 1;
			_budget_time -= (get_timer() - _time) / 1000;
		}
		
		if array_length(_remove) != 0 {
			LOG(_budget_runs < 0 || _budget_time < 0 ? Log.warn : Log.note, $"{array_length(_remove)} processed; {_budget_runs} {_budget_time}");
		}
		
		// remove elements without screwing up indicies
		array_sort(_remove, true);
		repeat array_length(_remove) {
			var _index = array_pop(_remove);
			array_delete(queue, _index, 1);
		}
		
	};
	
	/// @arg {struct.LoaderOption} _option
	static queue_add = function (_option) {
		array_push(self.queue, _option);
	};
	
	static setup = function () {
		for (var i_table = 0; i_table < array_length(self.file.toc); i_table++) {
			var _item = self.file.toc[i_table];
		
			var _field = {};
			
			var _val = _item.fields;
			
			switch _item.object {
				case nameof(obj_checkpoint):
					_field.index = _val.index;
					break;
				case nameof(obj_timer_start):
					_field.name = _val.name;
					_field.time = _val.time;
					_field.dir = _val.dir;
					_field.ref = _val.ref;
					break;
				case nameof(obj_timer_end):
					break;
			}
			
			_field.uid = _item.id;
			_field.rid = -1;
			
			_field.jorp_x = _item.x;
			_field.jorp_y = _item.y;
			_field.jorp_w = _item.width div TILESIZE;
			_field.jorp_h = _item.height div TILESIZE;
			
			var _inst = instance_create_layer(
				_item.x, _item.y,
				"Instances",
				asset_get_index(_item.object),
				_field
			);
			
			global.entities[$ _item.id] = _inst;
			global.entities_toc[$ _item.id] = _inst;
		}
	};
	
	static update = function () {
		var _cam = game_camera_get();
		
		for (var i = 0, _len = array_length(levels); i < _len; i++) {
			var _level = levels[i];
			
			if util_check_level_zone_load(_cam, _level) {
				if _level.loaded == LoaderProgress.out && _level.data == undefined {
					self.queue_add(new LoaderOptionFile(_level));
				
				} else if _level.loaded == LoaderProgress.prepared {
					self.queue_add(new LoaderOptionLoad(_level));
				
				} else if _level.loaded == LoaderProgress.loaded {
					_level.time_load = GAME_LOAD_TIME_FILE;
					_level.time_prep = GAME_LOAD_TIME_PREP;
					
				}
				
			} else if util_check_level_zone_prep(_cam, _level) {
				if _level.loaded == LoaderProgress.out && _level.data == undefined {
					self.queue_add(new LoaderOptionFile(_level));
				
				} else if _level.loaded == LoaderProgress.loaded {
					if _level.time_load-- <= 0 {
						// entities inside the level should automatically be destroyed now
						self.queue_add(new LoaderOptionUnload(_level));
					}
				
				} else if _level.loaded == LoaderProgress.prepared {
					_level.time_prep = GAME_LOAD_TIME_PREP;
				
				}
				
			} else {
				if _level.loaded == LoaderProgress.prepared {
					if _level.time_prep-- <= 0 {
						self.queue_add(new LoaderOptionDestroy(_level));
					}
				
				} else if _level.loaded == LoaderProgress.loaded {
					_level.time_load -= 4;
					if _level.time_load <= 0 {
						self.queue_add(new LoaderOptionUnload(_level));
					}
				
				}
			}
		}
		
		for (var i = 0; i < array_length(loaded); i++) {
			var _level = loaded[i];
			if _level.loaded != LoaderProgress.loaded {
				array_delete(loaded, i--, 1);
			}
		}
		
		self.queue_process();
		
		var _bin_ids = struct_get_names(bins);
		for (var i = 0; i < array_length(_bin_ids); i++) {
			var _b = bins[$ _bin_ids[i]];
			if _b[1] <= 0 {
				buffer_delete(_b[0]);
				struct_remove(bins, _bin_ids[i]);
			}
		}
		
		with obj_Exists {
			if (global.time + parity) % GAME_PARITY_ENTITY > 0 {
				continue;
			}
			var _lvl = game_level_get_safe_rect(bbox_left, bbox_top, bbox_right, bbox_bottom);
			if (_lvl == undefined || !_lvl.loaded) && outside(_cam) {
				instance_destroy();
			}
		}
		
		with obj_spike_bubble {
			if (global.time + parity) % GAME_PARITY_BUBBLE > 0 {
				continue;
			}
			var _lvl = game_level_get_safe(x, y);
			if (_lvl == undefined || !_lvl.loaded)
			&& rectangle_in_rectangle(
				x - 64, y - 64, x + 64, y + 64,
				_cam.x, _cam.y, _cam.x + _cam.w, _cam.y + _cam.h) {
				instance_destroy();
			}
		}
	};
}

function util_check_level_zone_prep(_cam, _level) {
	return rectangle_in_rectangle(
		_cam.x - GAME_LOAD_RADIUS_FILE,
		_cam.y - GAME_LOAD_RADIUS_FILE,
		_cam.x + _cam.w + GAME_LOAD_RADIUS_FILE,
		_cam.y + _cam.h + GAME_LOAD_RADIUS_FILE,
		_level.x, _level.y,
		_level.x + _level.width,
		_level.y + _level.height
	);
}

function util_check_level_zone_load(_cam, _level) {
	var _check = false;
	if instance_exists(obj_player) {
		_check = rectangle_in_rectangle(
			obj_player.bbox_left + min(0, obj_player.x_vel),
			obj_player.bbox_top + min(0, obj_player.y_vel),
			obj_player.bbox_left + max(0, obj_player.x_vel),
			obj_player.bbox_bottom + max(0, obj_player.y_vel),
			_level.x, _level.y,
			_level.x + _level.width,
			_level.y + _level.height
		) != 0;
	}
	return rectangle_in_rectangle(
		_cam.x - GAME_LOAD_RADIUS_ENTITY,
		_cam.y - GAME_LOAD_RADIUS_ENTITY,
		_cam.x + _cam.w + GAME_LOAD_RADIUS_ENTITY,
		_cam.y + _cam.h + GAME_LOAD_RADIUS_ENTITY,
		_level.x, _level.y,
		_level.x + _level.width,
		_level.y + _level.height
	) || _check;
}

enum LoaderOptionStatus {
	complete,
	running,
	wait,
}

function LoaderOption(_level, _priority) constructor {
	priority = _priority;
	level = _level;
	
	static process = function (_loader) {
		return LoaderOptionStatus.complete;
	};
	/// @arg {struct.Loader} _loader
	static collect = function (_loader) {
		static __out = [];
		return __out;
	};
}

/// loads a file into a buffer
function LoaderOptionFile(_level) : LoaderOption(_level, 0) constructor {
	bin = -1;
	load_id = -1;
	complete = false;
	state = 0;
	
	if DEBUG_LOAD_SLOW_ENABLE {
		slowdown = DEBUG_LOAD_SLOW_FILE;
	}
	
	level.loaded = LoaderProgress.prepping;
	
	LOG(Log.note, $"Loader(): created LoaderOptionFile {level.id}");
	
	static process = function (_loader) {

		if state == 0 {
			bin = buffer_create(0xffff, buffer_grow, 1);
			load_id = buffer_load_async(bin, level.name, 0, -1);
			array_push(obj_root.async_listen, self);
			state = 1;
		}
		
		if !complete {
			return LoaderOptionStatus.wait;
		}
		
		if DEBUG_LOAD_SLOW_ENABLE {
			if slowdown-- > 0 {
				return LoaderOptionStatus.wait;
			}
		}
		
		return LoaderOptionStatus.complete;
	};

	static collect = function (_loader) {
		ASSERT(buffer_exists(bin));
		
		var _bin_id = _loader.bin_top++;
		_loader.bins[$ _bin_id] = [bin, 1];
		
		static __out = array_create(1);
		__out[0] = new LoaderOptionParse(level, _bin_id);
		
		return __out;
	};
}

/// parses level information from buffer. the level is now "prepared"
function LoaderOptionParse(_level, _bin_id) : LoaderOption(_level, 0) constructor {
	bin_id = _bin_id;
	
	LOG(Log.note, $"Loader(): created LoaderOptionParse {level.id} (binid: {_bin_id})");
	
	static process = function (_loader) {
		ASSERT(_loader.bins[$ bin_id] != undefined);

		var _level = new Level(level.id, level.x, level.y, level.width, level.height);
		_level.init(_loader.bins[$ bin_id][0]);
		
		level.data = _level;
		level.loaded = LoaderProgress.prepared;
		
		_loader.bins[$ bin_id][1] -= 1;
		
		return LoaderOptionStatus.complete;
	};
	
	static collect = function (_loader) {
		var _cam = game_camera_get();
		
		var __out = [];
		array_delete(__out, 0, array_length(__out));
		
		if util_check_level_zone_load(_cam, level) {
			array_push(__out, new LoaderOptionLoad(level));
		}
		
		level.data.prepare(__out, level, _loader, bin_id);
		
		return __out;
	};
}

function LoaderOptionParsePart(_priority, _loader, _level, _bin_id, _self, _callback) : LoaderOption(_level, _priority) constructor {
	_loader.bins[$ _bin_id][1] += 1;
	
	LOG(Log.note, $"Loader(): created LoaderOptionParsePart {level.id}");
	
	bin_id = _bin_id;
	this = _self;
	callback = _callback;
	
	if DEBUG_LOAD_SLOW_ENABLE {
		slowdown = DEBUG_LOAD_SLOW_PARSE;
	}
	
	static process = function (_loader) {
		if DEBUG_LOAD_SLOW_ENABLE {
			if slowdown-- > 0 {
				return LoaderOptionStatus.running;
			}
		}
		
		callback(this, _loader.bins[$ bin_id][0]);
		
		_loader.bins[$ bin_id][1] -= 1;
		
		return LoaderOptionStatus.complete;
	};
}


/// creates level entities.
function LoaderOptionLoad(_level) : LoaderOption(_level, 0) constructor {
	LOG(Log.note, $"Loader(): created LoaderOptionLoad {level.id}");
	
	static process = function (_loader) {
		ASSERT(level.loaded == LoaderProgress.prepared);
		level.loaded = LoaderProgress.loaded;
		level.data.load();
		array_push(_loader.loaded, level);
		return LoaderOptionStatus.complete;
	};
}

function LoaderOptionUnload(_level) : LoaderOption(_level, 1) constructor {
	LOG(Log.note, $"Loader(): created LoaderOptionUnload {level.id}");
	
	static process = function (_loader) {
		if level.loaded != LoaderProgress.loaded {
			return LoaderOptionStatus.complete;
		}
		level.loaded = LoaderProgress.prepared;
		level.data.unload();
		return LoaderOptionStatus.complete;
	};
}

/// destroy level.
function LoaderOptionDestroy(_level) : LoaderOption(_level, 1) constructor {
	LOG(Log.note, $"Loader(): created LoaderOptionDestroy {level.id}");
	
	static process = function (_loader) {
		if level.loaded == LoaderProgress.out {
			return LoaderOptionStatus.complete;
		}
		ASSERT(level.loaded == LoaderProgress.prepared || level.loaded == LoaderProgress.loaded);
		level.loaded = LoaderProgress.out;
		level.data.unload();
		level.data.destroy();
		level.data = undefined;
		return LoaderOptionStatus.complete;
	};
}

