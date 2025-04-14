
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
 * error. pay attention to `assert()` where used.
 */


enum LoaderProgress {
	out,
	prepping,
	prepared,
	loaded,
}

/// responsible for all level loading related operations
function Loader() constructor {
	
	var _buffer = buffer_load("world.bin");
	if _buffer == -1 {
		log(Log.error, $"Loader(): file 'world.bin' doesn't exist");
		log(Log.error, "what do you even do about this?");
		assert(false);
	}
	var _file = level_unpack_bin_main(_buffer);
	buffer_delete(_buffer);
	
	
	levels = [];
	
	for (var i = 0; i < array_length(_file.rooms); i++) {
		var _room = _file.rooms[i];
		array_push(levels, {
			id: i,
			loaded: LoaderProgress.out,
			time_load: 0,
			time_prep: 0,
			x: _room.x,
			y: _room.y,
			width: _room.width,
			height: _room.height,
			name: $"room/{_room.name}.bin",
			data: undefined,
		});
	}
	
	// [Buffer.Id, Real]
	// [0] - the buffer we cache
	// [1] - how many depend on it
	bins = [];
	
	queue = [];
	
	static queue_process = function () {
		static __sort = function (_a, _b) {
			return _b.priority - _a.priority;
		};
		array_sort(queue, __sort);
		
		var _todo = [];
		for (var i = 0; i < array_length(queue); i++) {
			array_push(_todo, i);
		}
		
		var _remove = [];
		
		var _cam = game_camera_get();
		
		var _budget_runs = 4;
		var _budget_time = 60; // ms
		
		while array_length(_todo) != 0 {
			
			var _index = array_pop(_todo);
			var _item = queue[_index];
			
			var _status = LoaderOptionStatus.complete;
			
			if _item.priority == 0 && util_check_level_zone_load(_cam, _item.level) {
				
				// this item must be processed now
				// keep processing it until it is complete
				while true {
					_status = _item.process(self);
					assert(_status != undefined);
					
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
				assert(_status != undefined);
				
				if _status != LoaderOptionStatus.complete {
					// whatever
					continue;
				}
			}
			
			assert(_status == LoaderOptionStatus.complete);
			
			var _out = _item.collect(self);
			
			assert(is_array(_out));
			
			for (var i = 0; i < array_length(_out); i++) {
				assert(is_instanceof(_out[i], LoaderOption));
				
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
		}
		
		// remove elements without screwing up indicies
		array_sort(_remove, true);
		repeat array_length(_remove) {
			var _index = array_pop(_remove);
			array_delete(queue, _index, 1);
		}
		
	};
	
	
	for (var i_table = 0; i_table < array_length(_file.toc); i_table++) {
		var _item = _file.toc[i_table];
	
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
				
				_field.image_xscale = floor(_item.width / TILESIZE);
				_field.image_yscale = floor(_item.height / TILESIZE);
				break;
			case nameof(obj_timer_end):
				_field.image_xscale = floor(_item.width / TILESIZE);
				_field.image_yscale = floor(_item.height / TILESIZE);
				break;
		}
		
		_field.uid = _item.id;
		_field.rid = -1;
		
		var _inst = instance_create_layer(
			_item.x, _item.y,
			"Instances",
			asset_get_index(_item.object),
			_field
		);
		
		global.entities[$ _item.id] = _inst;
		global.entities_toc[$ _item.id] = _inst;
	}
	
	static update = function () {
		var _cam = game_camera_get();
		
		for (var i = 0; i < array_length(levels); i++) {
			var _level = levels[i];
			
			if util_check_level_zone_load(_cam, _level) {
				if _level.loaded == LoaderProgress.out && _level.data == undefined {
					array_push(self.queue, new LoaderOptionFile(_level));
				} else if _level.loaded == LoaderProgress.prepared {
					array_push(self.queue, new LoaderOptionLoad(_level));
				}
				
			} else if util_check_level_zone_prep(_cam, _level) {
				if _level.loaded == LoaderProgress.out && _level.data == undefined {
					array_push(self.queue, new LoaderOptionFile(_level));
				} else if _level.loaded == LoaderProgress.loaded {
					// entities inside the level should automatically be destroyed now
					_level.loaded = LoaderProgress.prepared;
				}
				
			} else {
				if _level.loaded == LoaderProgress.prepared {
					assert(false);
				} else if _level.loaded == LoaderProgress.loaded {
					assert(false);
				}
			}
		}
		
		self.queue_process();
		
		for (var i = 0; i < array_length(bins); i++) {
			if bins[i][1] <= 0 {
				buffer_delete(bins[i][0]);
				array_delete(bins, i, 1);
				i--;
			}
		}
		
	};

}

function util_check_level_zone_prep(_cam, _level) {
	var _pad = 128;
	return rectangle_in_rectangle(
		_cam.x - _pad,
		_cam.y - _pad,
		_cam.x + _cam.w + _pad,
		_cam.y + _cam.h + _pad,
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
		_cam.x, _cam.y,
		_cam.x + _cam.w,
		_cam.y + _cam.h,
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
		return [];
	};
}

/// loads a file into a buffer
function LoaderOptionFile(_level) : LoaderOption(_level, 0) constructor {
	bin = -1;
	
	level.loaded = LoaderProgress.prepping;
	
	log(Log.note, $"Loader(): created LoaderOptionFile {level.id}");
	
	static process = function (_loader) {
		bin = buffer_load(level.name);
		if bin == -1 {
			log(Log.error, $"Loader(): file '{level.name}' doesn't exist");
			assert(false);
		}
		return LoaderOptionStatus.complete;
	};

	static collect = function (_loader) {
		assert(buffer_exists(bin));
		
		array_push(_loader.bins, [bin, 1]);
		var _bin_id = array_length(_loader.bins) - 1;
		
		return [new LoaderOptionParse(level, _bin_id)];
	};
}

/// parses level information from buffer. the level is now "prepared"
function LoaderOptionParse(_level, _bin_id) : LoaderOption(_level, 0) constructor {
	bin_id = _bin_id;
	
	log(Log.note, $"Loader(): created LoaderOptionParse {level.id}");
	
	static process = function (_loader) {

		var _level = new Level(level.id, level.x, level.y, level.width, level.height);
		_level.init(_loader.bins[bin_id][0]);
		
		level.data = _level;
		level.loaded = LoaderProgress.prepared;
		
		_loader.bins[bin_id][1] -= 1;
		
		return LoaderOptionStatus.complete;
	};
	
	static collect = function (_loader) {
		var _cam = game_camera_get();
		if util_check_level_zone_load(_cam, level) {
			return [new LoaderOptionLoad(level)];
		} else {
			return [];
		}
	};
}

/// creates level entities.
function LoaderOptionLoad(_level) : LoaderOption(_level, 0) constructor {
	log(Log.note, $"Loader(): created LoaderOptionLoad {level.id}");
	
	static process = function (_loader) {
		assert(level.loaded == LoaderProgress.prepared);
		level.data.load();
		level.loaded = LoaderProgress.loaded;
		return LoaderOptionStatus.complete;
	};
}

/// destroy level.
function LoaderOptionDestroy(_level) : LoaderOption(_level, 0) constructor {
	log(Log.note, $"Loader(): created LoaderOptionDestroy {level.id}");
	
	static process = function (_loader) {
		assert(false);
	};
}

