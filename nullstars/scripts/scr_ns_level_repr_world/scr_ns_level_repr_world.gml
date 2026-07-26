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
		// there are three parts to this method.
		// first, we check what state we need to set any relevant room to.
		// second, we tick room components.
		// third, we tick every entity.
		
		// this variable is load bearing to tell if a room is outside
		// any radius. (explained later)
		frame += 1;
		
		var _cam := nullstars_get_cam();
		var _config := ns_config();
		
		// check rooms for loading.
		static __list := ds_list_create();
		
		// step 1 -- set room states
		
		// a few assumptions with the following logic depends on this.
		// like what the fuck are you doing if this doesn't hold anyways? lol?
		ASSERT_DEBUG(_config.game_loader_radius_file < _config.game_loader_radius_parse);
		ASSERT_DEBUG(_config.game_loader_radius_parse < _config.game_loader_radius_load);
		
		var _len;
		var _radius;
		
		// this checking is done with collision functions.
		// now, this probably isn't the fastest. especially for a really large world, it
		// might honestly be faster to implement a quad-tree? at least then gamemaker
		// wouldn't worry about the obj_room objects.
		// probably not.
		// either way, even this might be faster, just one collision_rectangle_list()
		// and then manually doing collision checks with whats found. it really depends
		// on the cost of collision_rectangle_list(). profiling is required.
		
		// first check the file radius.
		ds_list_clear(__list);
		
		_radius := _config.game_loader_radius_file;
		_len := collision_rectangle_list(
			_cam.x - _radius,
			_cam.y - _radius,
			_cam.x + _cam.w + _radius * 2,
			_cam.y + _cam.h + _radius * 2,
			obj_room, false, true, __list, false
		);
		
		for (var i = 0; i < _len; i++) {
			// spam the room with a helpful suggestion!
			var _room := __list[| i].parent;
			
			_room.target = ns_level_RoomTarget.File;
			_room.target_frame = self.frame; // foreshadowing
			
			// add to rooms_loaded. they aren't technically "loaded", but
			// idk a better succinct common word. under consideration lol.
			if array_get_index(self.rooms_loaded, _room) == -1 {
				array_push(self.rooms_loaded, _room);
			}
		}
		
		// now check the parse radius.
		ds_list_clear(__list);
		
		_radius := _config.game_loader_radius_parse;
		_len := collision_rectangle_list(
			_cam.x - _radius,
			_cam.y - _radius,
			_cam.x + _cam.w + _radius * 2,
			_cam.y + _cam.h + _radius * 2,
			obj_room, false, true, __list, false
		);
		
		for (var i = 0; i < _len; i++) {
			var _room := __list[| i].parent;
			_room.target = ns_level_RoomTarget.Parse;
		}
		
		// finally check the load radius.
		ds_list_clear(__list);
		
		_radius := _config.game_loader_radius_load;
		_len := collision_rectangle_list(
			_cam.x - _radius,
			_cam.y - _radius,
			_cam.x + _cam.w + _radius * 2,
			_cam.y + _cam.h + _radius * 2,
			obj_room, false, true, __list, false
		);
		
		for (var i = 0; i < _len; i++) {
			var _room := __list[| i].parent; // fucking kill me
			_room.target = ns_level_RoomTarget.Load;
		}
		
		// step 2 -- distribute work among the rooms
		
		// goobinator 5000
		
		var _budget := new ns_level_Budget();
		
		// this will control whether we update entities later.
		var _pause = false;
		
		// cache...
		_len := array_length(self.rooms_loaded);
		
		// do the "important" rooms first
		for (var i = 0; i < _len; i++) {
			var _room := self.rooms_loaded[i];
			
			// okay okay so quick aside
			// we need to remove rooms from rooms_loaded when they are outside
			// of the file radius. unfortunately, there isn't anything like a
			// not_collision_rectangle_list() in gamemaker, here we avoid yet another
			// collision_rectangle().
			// _room.target_frame is updated to self.frame every tick if it's in the file
			// radius, so if a room isn't updated, obviously it's outside the file radius.
			if _room.target_frame != self.frame {
				_room.target = ns_level_RoomTarget.Unload;
			}
			
			if _room.target != ns_level_RoomTarget.Load {
				continue;
			}
			
			while true {
				var _status := _room.tick_components(_room.target, _budget);
				
				if _status == ns_level_RoomComponentStatus.Running {
					continue;
				}
				else if _status == ns_level_RoomComponentStatus.Waiting {
					_pause = true;
				}
				
				break;
			}
		}
		
		var i = 0;
		var _count = 0;
		while true {
			if i >= _len {
				if _count == i {
					break;
				}
				
				i = 0;
				_count = 0;
			}
			
			if !_budget.okay() {
				break;
			}
			
			var _room := self.rooms_loaded[i];
			
			if _room.target == ns_level_RoomTarget.Load {
				_count++;
				i++;
				continue;
			}
			
			var _status := _room.tick_components(_room.target, _budget);
			
			if _status == ns_level_RoomComponentStatus.Complete {
				if _room.target == ns_level_RoomTarget.Unload {
					array_delete(self.rooms_loaded, i, 1);
					i--;
					_count--;
					_len--;
				}
				
				_count++;
			}
			
			i++;
		}
		
		// speaking of,
		if _pause {
			LOG(Log.Warn, $"{nameof(ns_level_World)}(): paused on this frame ({self.frame})");
			return;
		}
		
		_len := array_length(rooms_loaded);
		for (var i = 0; i < _len; i++) {
			var _room := rooms_loaded[i];
			_room.tick_entities();
		}
		
		if !entities_global_sorted {
			// todo:
			// array_sort(entities_global);
		}
		
		_len := array_length(entities_global);
		for (var i = 0; i < _len; i++) {
			var _entity := entities_global[i];
			_entity.fn_tick();
		}
	};
	
	static entity_global_add := function (_entity) {
		ASSERT(object_is_ancestor(_entity, obj_Entity));
		array_push(entities_global, _entity);
		entities_global_sorted = false;
	};
}
