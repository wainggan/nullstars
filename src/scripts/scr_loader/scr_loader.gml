

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
	
	// [String, Real, ...]
	// [0] - instruction type
	// [1] - priority
	queue = [];
	
	/// @arg {struct.LoaderOption} _option
	static queue_add = function (_option) {
		if array_length(queue) == 0 {
			array_push(queue, _option);
			return;
		}
		for (var i = 0; i < array_length(queue); i++) {
			if queue[i].priority <= _option.priority {
				array_insert(queue, i, _option);
				return;
			}
		}
	}
	
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
		
		var _budget_runs = 1;
		var _budget_time = 0.5;
		
		while array_length(_todo) != 0 {
			
			var _index = array_pop(_todo);
			var _item = queue[_index];
			
			if _item.priority == 0 && util_check_level_zone_load(_cam, _item.level) {
				while true {
					var _status = _item.process(self);
					if _status == LoaderOptionStatus.complete {
						break;
					}
					if _status == LoaderOptionStatus.wait {
						global.game.state.set_pause_freeze(true);
						break;
					}
				}
				
				var _out = _item.collect();
				
				for (var i = 0; i < array_length(_out); i++) {
					if is_instanceof(_out[i], LoaderOption) {
						array_push(queue, _out[i]);
						array_push(_todo, array_length(queue) - 1);
						// todo: sort?
					} else {
						// gonna guess this is a buffer lol
						array_push(bins, out[i]);
					}
				}
				
				array_push(_remove, _index);
				
			}
			
		}
		
		for (var i = array_length(queue) - 1; i >= 0; i--) {
			var _item = queue[i];
			
			if _item.priority == 0 && util_check_level_zone_load(_cam, _item.level) {
				
				while true {
					var _status = _item.process(self);
					if _status == LoaderOptionStatus.complete {
						break;
					}
					if _status == LoaderOptionStatus.wait {
						global.game.state.set_pause_freeze(true);
						break;
					}
				}
				
				array_delete(queue, i, 1);
				
			} else if _budget_runs > 0 && _budget_time > 0 {
				
				var _status = _item.process(self);
				if _status == LoaderOptionStatus.complete {
					array_delete(queue, i , 1);
				}
				
			}
			
			
		}
	};
	
	
	static queue_process_file = function (_base) {
		var _data = _base[1];
		
		var _buffer = buffer_load(_data.name);
		if _buffer == -1 {
			log(Log.error, $"Loader(): file '{_data.name}' doesn't exist");
			throw "oops";
		}
		array_push(bins, [_buffer, 0]);
		queue_add_prep(_base, array_length(bins) - 1);
	};
	
	static queue_process_prep = function (_base) {
		var _data = _base[1];
		var _bin_id = _base[2];
		
		var _level = new Level(_data.id, _data.x, _data.y, _data.width, _data.height);
		_level.init(bins[_bin_id][0]);
		
		_data.data = _level;
		_data.loaded = LoaderProgress.prepared;
		
		bins[_bin_id][1] -= 1;
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
			
			if util_check_level_zone_prep(_cam, _level) {
				if _level.loaded == LoaderProgress.out && _level.data != undefined {
					self.queue_add_file(_level);
				} else if _level.loaded = LoaderProgress.prepared {
					_level.time_prep = 60 * 4;
				}
				
			} else if util_check_level_zone_load(_cam, _level) {
				if _level.loaded == LoaderProgress.out && _level.data != undefined {
					self.queue_add_file(_level);
				} else if _level.loaded == LoaderProgress.prepared {
					_level.time_prep = 60 * 4;
				} else if _level.loaded == LoaderProgress.loaded {
					_level.time_load = 60 * 10;
				}
				
			} else {
				if _level.loaded == LoaderProgress.prepared {
					
				} else if _level.loaded == LoaderProgress.loaded {
					_level.time_load -= 1;
					if _level.time_load <= 0 {
						_level.data.destroy();
						delete _level.data;
						_level.loaded = LoaderProgress.out;
					}
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
	return rectangle_in_rectangle(
		_cam.x, _cam.y,
		_cam.x + _cam.w,
		_cam.y + _cam.h,
		_level.x, _level.y,
		_level.x + _level.width,
		_level.y + _level.height
	) || rectangle_in_rectangle(
		obj_player.bbox_left + min(0, obj_player.x_vel),
		obj_player.bbox_top + min(0, obj_player.y_vel),
		obj_player.bbox_left + max(0, obj_player.x_vel),
		obj_player.bbox_bottom + max(0, obj_player.y_vel),
		_level.x, _level.y,
		_level.x + _level.width,
		_level.y + _level.height
	);
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
	static collect = function () {
		return [];
	};
}

function LoaderOptionFile(_level) : LoaderOption(_level, 0) constructor {
	bin = -1;
	
	static process = function (_loader) {
		bin = buffer_load(level.name);
		if bin == -1 {
			log(Log.error, $"Loader(): file '{level.name}' doesn't exist");
			throw "oops";
		}
		return LoaderOptionStatus.complete;
	};

	static collect = function () {
		return [bin, ];
	};
}

