/**
@arg {struct.Package} _package
*/
function ns_level_World(_package) constructor {
	LOG(Log.Note, $"{nameof(ns_level_World)}(): initializing");
	
	// index of all loaded entities.
	entities_all := [];
	
	// global entities, not owned by a room.
	entities_global := [];
	
	entities_global_sorted = true;
	
	// all rooms. after being filled, this should never be touched.
	rooms_list := [];
	
	// all rooms, as a map.
	rooms_map := {};
	
	// populate rooms
	// todo: move to another function
	{
		var _buffer := _package.load_world_root();
		
		var _magic_nullstars := buffer_read(_buffer, buffer_string);
		// todo: proper error reporting
		ASSERT_EQ(_magic_nullstars, "nullstars");
		
		var _magic_number := buffer_read(_buffer, buffer_string);
		ASSERT_EQ(_magic_number, "W");
		
		var _version := buffer_read(_buffer, buffer_u16);
		
		var _rooms_length := buffer_read(_buffer, buffer_u32);
		
		array_resize(rooms_list, _rooms_length);
		
		for (var i = 0; i < _rooms_length; i++) {
			var _room_id := buffer_read(_buffer, buffer_string);
			var _room_x := buffer_read(_buffer, buffer_s32);
			var _room_y := buffer_read(_buffer, buffer_s32);
			var _room_width := buffer_read(_buffer, buffer_u32);
			var _room_height := buffer_read(_buffer, buffer_u32);
			
			var _room_inst := new ns_level_Room(self, _room_id, _room_x, _room_y, _room_width, _room_height);
			
			rooms_list[i] := _room_inst;
			rooms_map[$ _room_id] := _room_inst;
			
		}
	
		buffer_delete(_buffer);
	}
	
	frame = 0;
	
	// currently loaded rooms.
	rooms_loaded := [];
	
	// task queue.
	queue := [];
	
	queue_sorted = true;
	
	rules := (new ns_level_AutotileCompiler().compile(ns_level_json_test()));
	
	static tick := function () {
		frame += 1;
		
		var _cam := nullstars_get_cam();
		var _config := ns_config();
		
		// check rooms for loading.
		static __list := ds_list_create();
		
		ds_list_clear(__list);
		
		var _len;
		var _radius;
		
		_radius := _config.game_loader_radius_file;
		_len := collision_rectangle_list(
			_cam.x - _radius,
			_cam.y - _radius,
			_cam.x + _cam.w + _radius * 2,
			_cam.y + _cam.h + _radius * 2,
			obj_room,
			false,
			true,
			__list,
			false
		);
		
		for (var i = 0; i < _len; i++) {
			// spam the room with a helpful suggestion!
			var _room := __list[| i].parent;
			_room.target = ns_level_RoomTarget.File;
			_room.target_frame = self.frame;
			if array_get_index(self.rooms_loaded, _room) == -1 {
				array_push(self.rooms_loaded, _room);
			}
		}
		
		ds_list_clear(__list);
		
		_radius := _config.game_loader_radius_parse;
		_len := collision_rectangle_list(
			_cam.x - _radius,
			_cam.y - _radius,
			_cam.x + _cam.w + _radius * 2,
			_cam.y + _cam.h + _radius * 2,
			obj_room,
			false,
			true,
			__list,
			false
		);
		
		for (var i = 0; i < _len; i++) {
			var _room := __list[| i].parent;
			_room.target = ns_level_RoomTarget.Parse;
		}
		
		ds_list_clear(__list);
		
		_radius := _config.game_loader_radius_load;
		_len := collision_rectangle_list(
			_cam.x - _radius,
			_cam.y - _radius,
			_cam.x + _cam.w + _radius * 2,
			_cam.y + _cam.h + _radius * 2,
			obj_room,
			false,
			true,
			__list,
			false
		);
		
		// fucking kill me
		for (var i = 0; i < _len; i++) {
			var _room := __list[| i].parent;
			_room.target = ns_level_RoomTarget.Load;
		}
		
		// at this point, rooms have been pinged and will be working on
		// whatever they need to when the queue is ticked.
		
		// entities will be ticked after the queue is ticked. that way, if a
		// queue item is stuck on WorldTaskStatus.Waiting, entities can be safely paused.
		
		var _budget := new ns_level_Budget();
		
		var _pause = false;
		
		_len := array_length(self.rooms_loaded);
		for (var i = 0; i < _len; i++) {
			var _room := self.rooms_loaded[i];
			
			if _room.target_frame != self.frame {
				_room.target = ns_level_RoomTarget.Unload;
			}
			
			var _status := _room.tick_components(_room.target, _budget);
			
			if _status == ns_level_RoomComponentStatus.Waiting {
				_pause = true;
			}
			else if _room.target_frame != self.frame && _status == ns_level_RoomComponentStatus.Complete {
				array_delete(self.rooms_loaded, i, 1);
				i--;
				_len--;
			}
		}
		
		// speaking of,
		if _pause {
			Log(Log.Warn, $"{nameof(ns_level_World)}(): paused on this frame ({self.frame})");
			return;
		}
		
		self.entity_process();
	};
	
	static entity_global_add := function (_entity) {
		ASSERT(object_is_ancestor(_entity, obj_Entity));
		array_push(entities_global, _entity);
		entities_global_sorted = false;
	};
	
	static entity_process := function () {
		for (var i = 0, _len := array_length(rooms_loaded); i < _len; i++) {
			var _room := rooms_loaded[i];
			_room.tick_entities();
		}
		
		if !entities_global_sorted {
			// todo:
			// array_sort(entities_global);
		}
		
		for (var i = 0, _len := array_length(entities_global); i < _len; i++) {
			var _entity := entities_global[i];
			_entity.fn_tick();
		}
	};
	
	// goobinator 5000
}
