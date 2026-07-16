/**
@arg {struct.Package} _package
*/
function ns_level_World(_package) constructor {
	LOG(Log.Note, "ns_level_World(): initializing");
	
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
	
	// currently loaded rooms.
	rooms_loaded := [];
	
	// task queue.
	queue := [];
	
	queue_sorted = true;
	
	rules := (new ns_level_AutotileCompiler().compile(nullstars_level_json_test()));
	
	static tick := function () {
		var _cam := nullstars_get_cam();
		var _config := nullstars_config();
		
		// check rooms for loading.
		static __list := ds_list_create();
		
		ds_list_clear(__list);
		
		collision_rectangle_list(
			_cam.x - _config.game_loader_radius_file,
			_cam.y - _config.game_loader_radius_file,
			_cam.x + _cam.w + _config.game_loader_radius_file * 2,
			_cam.y + _cam.h + _config.game_loader_radius_file * 2,
			obj_room,
			false,
			true,
			__list,
			false
		);
		
		for (var i = 0, _len := ds_list_size(__list); i < _len; i++) {
			// spam the room with a helpful suggestion!
			var _room := __list[| i].parent;
		}
		
		ds_list_clear(__list);
		
		collision_rectangle_list(
			_cam.x - _config.game_loader_radius_parse,
			_cam.y - _config.game_loader_radius_parse,
			_cam.x + _cam.w + _config.game_loader_radius_parse * 2,
			_cam.y + _cam.h + _config.game_loader_radius_parse * 2,
			obj_room,
			false,
			true,
			__list,
			false
		);
		
		for (var i = 0, _len := ds_list_size(__list); i < _len; i++) {
			var _room := __list[| i].parent;
		}
		
		ds_list_clear(__list);
		
		collision_rectangle_list(
			_cam.x - _config.game_loader_radius_load,
			_cam.y - _config.game_loader_radius_load,
			_cam.x + _cam.w + _config.game_loader_radius_load * 2,
			_cam.y + _cam.h + _config.game_loader_radius_load * 2,
			obj_room,
			false,
			true,
			__list,
			false
		);
		
		// fucking kill me
		for (var i = 0, _len := ds_list_size(__list); i < _len; i++) {
			var _room := __list[| i].parent;
		}
		
		// at this point, rooms have been pinged and will be working on
		// whatever they need to when the queue is ticked.
		
		// entities will be ticked after the queue is ticked. that way, if a
		// queue item is stuck on WorldTaskStatus.Waiting, entities can be safely paused.
		
		var _budget := new ns_level_Budget();
		
		var _pause = false;
		
		for (var i = 0, _len := array_length(self.rooms_list); i < _len; i++) {
			var _room := self.rooms_list[i];
			
			var _status := _room.tick_components(ns_level_RoomTarget.File, _budget);
			
			if _status == ns_level_RoomComponentStatus.Waiting {
				_pause = true;
			}
		}
		
		// speaking of,
		if _pause {
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
