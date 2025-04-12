

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
	
	// [String, ...]
	// [0] - instruction type
	// [1] - priority
	queue = [];
	
	static queue_add = function (_base) {
		if array_length(queue) == 0 {
			array_push(queue, _base);
			return;
		}
		for (var i = 0; i < array_length(queue); i++) {
			if queue[i][1] <= _base[1] {
				array_insert(queue, i, _base);
				return;
			}
		}
	}
	
	static queue_add_file = function (_level) {
		log(Log.note, $"Loader(): queue_add_file {_level.name} ({_level.id})");
		_level.loaded = LoaderProgress.prepping;
		self.queue_add(["file", 0, _level]);
	};
	
	static queue_add_prep = function (_level, _bin_id) {
		log(Log.note, $"Loader(): queue_add_prep {_level.name} ({_level.id})");
		bins[_bin_id][1] += 1;
		self.queue_add(["prep", 0, _level, _bin_id]);
	};
	
	static queue_process = function () {
		// HERE: this now needs to take one item at a time
		while array_length(queue) != 0 {
			var _item = array_pop(queue);
			
			if _item[0] == "file" {
				queue_process_file(_item);
			} else if _item[0] == "prep" {
				queue_process_prep(_item);
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

