

enum LoaderProgress {
	out,
	loading,
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
			time: 0,
			x: _room.x,
			y: _room.y,
			width: _room.width,
			height: _room.height,
			name: $"room/{_room.name}.bin",
			data: undefined,
		});
	}
	
	loaded = [];
	
	// [Buffer.Id, Real]
	// [0] - the buffer we cache
	// [1] - how many depend on it
	bins = [];
	
	// [String, ...]
	// [0] - instruction type
	queue = [];
	
	static queue_add_file = function (_base) {
		_base.loaded = LoaderProgress.loading;
		array_push(queue, ["file", _base]);
	};
	
	static queue_add_load = function (_base, _bin_id) {
		bins[_bin_id][1] += 1;
		array_push(queue, ["load", _base, _bin_id]);
	};
	
	static queue_process = function () {
		while array_length(queue) != 0 {
			var _item = array_pop(queue);
			
			if _item[0] == "file" {
				queue_process_file(_item);
			} else if _item[0] == "load" {
				queue_process_load(_item);
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
		queue_add_load(_base, array_length(bins) - 1);
		
	};
	
	static queue_process_load = function (_base) {
		var _data = _base[1];
		var _bin_id = _base[2];
		
		var _level = new Level(_data.id, _data.x, _data.y, _data.width, _data.height);
		_level.init(bins[_bin_id][0]);
		
		_data.data = _level;
		array_push(loaded, _data);
		
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
			if rectangle_in_rectangle(
				_cam.x, _cam.y,
				_cam.x + _cam.w,
				_cam.y + _cam.h,
				_level.x, _level.y,
				_level.x + _level.width,
				_level.y + _level.height
			) {
				if _level.loaded == LoaderProgress.out && _level.data != undefined {
					self.queue_add_file(_level);
				} else if _level.loaded == LoaderProgress.loaded {
					_level.time = 60 * 10;
				}
			} else {
				if _level.loaded == LoaderProgress.loaded {
					_level.time -= 1;
					if _level.time <= 0 {
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

