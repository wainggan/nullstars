/*
the world loader.

this is the beating heart of nullstars, and likely the most complex part of this game.
*/

/**
@arg {struct.Package} _package
*/
function WorldMain(_package) constructor {
	LOG(Log.Note, "WorldMain(): initializing");
	
	// index of all loaded entities.
	entities_all := [];
	
	// global entities, not owned by a room.
	entities_global := [];
	
	entities_global_sorted = true;
	
	// all rooms. after being filled, this should never be touched.
	rooms := [];
	
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
		
		array_resize(rooms, _rooms_length);
		
		for (var i = 0; i < _rooms_length; i++) {
			var _room_id := buffer_read(_buffer, buffer_string);
			var _room_x := buffer_read(_buffer, buffer_s32);
			var _room_y := buffer_read(_buffer, buffer_s32);
			var _room_width := buffer_read(_buffer, buffer_u32);
			var _room_height := buffer_read(_buffer, buffer_u32);
			rooms[i] := new WorldRoom(self, _room_id, _room_x, _room_y, _room_width, _room_height);
		}
	
		buffer_delete(_buffer);
	}
	
	// currently loaded rooms.
	rooms_loaded := [];
	
	// task queue.
	queue := [];
	
	queue_sorted = true;
	
	rules := (new WorldAutotileCompiler().compile(nullstars_world_get_test()));
	
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
			var _room = __list[| i].parent;
			if _room.state == WorldRoomState.Empty {
				_room.filing();
			}
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
			var _room = __list[| i].parent;
			if _room.state == WorldRoomState.Filed {
				_room.parsing();
			}
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
			var _room = __list[| i].parent;
			if _room.state == WorldRoomState.Parsed {
				_room.loading();
			}
		}
		
		// at this point, rooms have been pinged and will be working on
		// whatever they need to when the queue is ticked.
		
		// entities will be ticked after the queue is ticked. that way, if a
		// queue item is stuck on WorldTaskStatus.Waiting, entities can be safely paused.
		
		// speaking of,
		var _pause = queue_process();
		if _pause {
			return;
		}
		
		entity_process();
	};
	
	static entity_global_add := function (_entity) {
		ASSERT(object_is_ancestor(_entity, obj_Entity));
		array_push(entities_global, _entity);
		entities_global_sorted = false;
	};
	
	static entity_process := function () {
		for (var i = 0, _len := array_length(rooms_loaded); i < _len; i++) {
			var _room := rooms_loaded[i];
			_room.tick();
		}
		
		if !entities_global_sorted {
			// todo:
			// array_sort(entities_global);
		}
		
		for (var i = 0, _len := array_length(entities_global); i < _len; i++) {
			var _entity := entities_global[i];
			_entity.tick();
		}
	};
	
	static queue_add := function (_task) {
		ASSERT(is_instanceof(_task, WorldTask));
		array_push(queue, _task);
		queue_sorted = false;
	};
	
	// goobinator 5000
	static queue_process := function () {
		var _config = nullstars_config();
		
		// time to process the queue!
		
		static __sort := function (_a, _b) {
			return _b.priority - _a.priority;
		};
		
		if !queue_sorted {
			array_sort(queue, __sort);
			queue_sorted = true;
		}
		
		// value to return from this function.
		// set to true to indicate that the game should freeze for a frame.
		var _return_freeze = false;
		
		// we only have a limited budget to process these things. if we run out of either
		// of these, then we need to stop processing.
		
		// how much time in milliseconds we have.
		// the most important one, this makes sure that the rest of the
		// game has enough time to process too.
		var _budget_time = _config.game_loader_budget_time; // ms
		// how much tasks we can process, total.
		// this will prevent a WorldTaskStatus.Waiting task from devolving into a hot loop.
		var _budget_count = _config.game_loader_budget_count;
		
		var _debug_track;
		if DEBUG_LOAD_TRACK_OPS {
			_debug_track := [];
		}
		
		static __remove := [];
		
		array_resize(__remove, 0);
		
		// using a todo list because it makes it easier to deal with
		// new tasks getting added during processing.
		static __todo := [];
		
		array_resize(__todo, array_length(queue));
		for (var i = 0, _len := array_length(queue); i < _len; i++) {
			__todo[i] = i;
		}
			
		// note: queue must be essentially immutable during this
		while array_length(__todo) != 0 {
				
			var _time := get_timer();
			
			var _index := array_pop(__todo);
				
			var _task := queue[_index];
				
			var _status = WorldTaskStatus.Running;
				
			// todo: add collision check
			// priority == 0 means they must be processed when in load range.
			if _task.priority == 0 && true {
				if DEBUG_LOAD_TRACK_OPS {
					array_push(_debug_track, instanceof(_task));
				}
				
				while true {
					_status = _task.process(self);
					ASSERT_NE(_status, undefined, $"{instanceof(_task)}");
					
					if _status == WorldTaskStatus.Complete {
						break;
					}
					if _status == WorldTaskStatus.Waiting {
						break;
					}
				}
					
				// if it must wait for the next frame to
				// be processed, freeze the game for a frame.
				if _status == WorldTaskStatus.Waiting {
					// deal with budget
					_budget_count -= 1;
					_budget_time -= (get_timer() - _time) / 1000;
					
					if DEBUG_LOAD_TRACK_OPS {
						array_push(_debug_track, (get_timer() - _time) / 1000);
					}
					
					_return_freeze = true;
					continue;
				}
			}
			else if _budget_time > 0 && _budget_count > 0 {
				if DEBUG_LOAD_TRACK_OPS {
					array_push(_debug_track, instanceof(_task));
				}
				
				// this item can be processed over multiple frames.
				_status = _task.process(self);
				ASSERT_NE(_status, undefined, $"{instanceof(_task)}");
				
				if _status != WorldTaskStatus.Complete {
					// deal with budget
					_budget_count -= 1;
					_budget_time -= (get_timer() - _time) / 1000;
					
					if DEBUG_LOAD_TRACK_OPS {
						array_push(_debug_track, (get_timer() - _time) / 1000);
					}
					
					// whatever
					continue;
				}
			}
			else {
				// this path happens when the budget runs out.
				// this will simply keep running the loop until complete.
				
				continue;
			}
			
			ASSERT_EQ(_status, WorldTaskStatus.Complete);
			
			var _out := _task.collect(self);
			
			ASSERT(is_array(_out));
			
			for (var i = 0, _len := array_length(_out); i < _len; i++) {
				ASSERT(is_instanceof(_out[i], WorldTask));
				
				// if we recieve a task, we need to add it to
				// the queue *and* todo list. this ensures that if it turns
				// out to be a priority 0 option, it gets dealt with correctly later
				queue_add(_out[i]);
				array_push(__todo, array_length(queue) - 1);
				// todo: sort?
			}
			
			// the item was complete, so remove it
			array_push(__remove, _index);
			
			// deal with budget
			_budget_count -= 1;
			_budget_time -= (get_timer() - _time) / 1000;
			
			if DEBUG_LOAD_TRACK_OPS {
				array_push(_debug_track, (get_timer() - _time) / 1000);
			}
		}
		
		if array_length(__remove) != 0 {
			LOG(_budget_count < 0 || _budget_time < 0 ? Log.Warn : Log.Note, $"{array_length(__remove)} processed; {_budget_count} {_budget_time}");
			if DEBUG_LOAD_TRACK_OPS {
				var _debug_track_str = "types: ";
				while array_length(_debug_track) != 0 {
					_debug_track_str += string(array_pop(_debug_track));
					_debug_track_str += ", ";
				}
				LOG(Log.Note, _debug_track_str);
			}
		}
		
		// remove elements without screwing up indicies
		array_sort(__remove, true);
		while array_length(__remove) != 0 {
			var _index = array_pop(__remove);
			array_delete(queue, _index, 1);
		}
		
		return _return_freeze;
	};
}

/*
rooms have state associated with how loaded they are.

the state graph is as follows:

Empty -> Filing -> Filed -> Parsing -> Parsed -> Loading -> Loaded
  ^---- Unfiling <--' ^--- Unparsing <--'  ^--- Unloading <--'

WorldLoader will inform WorldRoom() that it needs to change state, WorldRoom()
will add new Tasks to WorldLoader().

each state here represents a discrete step in the level loading process. there
is only one way to reach a 'Loaded' room, through a 'Parsed' room.

'Empty' means the room is completely unloaded. switch to 'Filing' when the room is
in the file radius.

'Filing' will open the file, changing state to 'Filed' when complete. switch
to 'Parsing' when the room is in the parse radius.

'Parsing' will take the contents of the file and completely unpack its
data. when complete, the state will be 'Parsed', and all the layers will
be created, all entities will be ready to be created. switch to 'Loading'
when the room is in the loading radius.

'Loading' will create the rest of the required resources from what has been
parsed, notably initializing all the room's game objects. the room is now 'Loaded'!
*/

enum WorldRoomState {
	Empty,
	
	Filing,
	Filed,
	Unfiling,
	
	Parsing,
	Parsed,
	Unparsing,
	
	Loading,
	Loaded,
	Unloading,
}

/**
@arg {struct.WorldMain} _world
@arg {string} _id
@arg {real} _x in tiles
@arg {real} _y in tiles
@arg {real} _width in tiles
@arg {real} _height in tiles
*/
function WorldRoom(_world, _id, _x, _y, _width, _height) constructor {
	LOG(Log.Hide, $"WorldRoom(): initializing (@ {_id}; {_x} {_y} {_width} {_height})");
	
	world := _world;
	
	id := _id;
	// in tiles
	x := _x;
	y := _y;
	width := _width;
	height := _height;
	
	// used for collision testing
	object := instance_create_layer(_x, _y, "Instances", obj_room);
	with object {
		parent = other;
		image_xscale = _width;
		image_yscale = _height;
	}
	
	// entities owned by the room.
	entities := [];
	
	state = WorldRoomState.Empty;
	
	buffer = undefined;
	buffer_map = undefined;
	
	/*
	used for collisions.
	not intended to be drawn !!
	
	0b0000_0000_0000_000x
	x => solid or semisolid
		0: => solid
			0b0000_0000_xxxx_xx00
			x => solid tileset
				0 => empty
				... => tileset
		1: => semisolid
			0b0000_0000_0000_xx01
			x => direction
				0b00 (0) => facing right
				0b01 (1) => facing up
				0b10 (2) => facing left
				0b11 (3) => facing down
	
	note that a zeroed out tile corresponds to a
	tile entirely without collisions >:3
	*/
	// unfortunately we can't use the tilemap without a layer.
	layer_solid_base = undefined;
	layer_solid_tilemap = undefined;
	
	/*
	used for collisions and drawing.
	0 => none
	1 => facing right
	2 => facing up
	3 => facing left
	4 => facing down
	*/
	layer_spike_base = undefined;
	layer_spike_tilemap = undefined;
	
	/*
	used for drawing.
	*/
	layer_graphic_front_vb = undefined;
	
	static tick := function () {
		// update entities.
		
		
	};
	
	static filing := function () {
		ASSERT_EQ(state, WorldRoomState.Empty);
		state = WorldRoomState.Filing;
		world.queue_add(new WorldTaskFile(nullstars_root().async, self));
	};
	
	static parsing := function () {
		ASSERT_EQ(state, WorldRoomState.Filed);
		state = WorldRoomState.Parsing;
		world.queue_add(new WorldTaskParse(self));
	};
	
	static loading := function () {
		ASSERT_EQ(state, WorldRoomState.Parsed);
		state = WorldRoomState.Loading;
	};
	
	static purge := function () {
		for (var i = 0, _len := array_length(entities); i < _len; i++) {
			var _entity := entities[i];
			
			// entities are not allowed to destroy themselves.
			ASSERT(instance_exists(_entity), "entity does not exist");
			
			// if the entity is still on screen, then they need to stay loaded. add them to the global entity list.
			// otherwise, they are destroyed.
			
			if !_entity.fn_outside() {
				array_push(world.entities, _entity);
			}
			else {
				instance_destroy(_entity);
			}
		}
	};
	
	static destroy := function () {
		instance_destroy(object);
	};
}

enum WorldTaskStatus {
	Complete,
	Waiting,
	Running,
}

/**
@arg {struct.WorldRoom} _room
@arg {real} _priority
*/
function WorldTask(_room, _priority) constructor {
	parent := _room;
	priority := _priority;

	static process := function () {
		return WorldTaskStatus.Complete;
	};
	
	static collect := function () {
		static __return := [];
		return __return;
	};
}

/**
@arg {struct.AsyncHook} _async
@arg {struct.WorldRoom} _room
@arg {real} _priority
*/
function WorldTaskFile(_async, _room) : WorldTask(_room, 0) constructor {
	LOG(Log.Note, $"WorldTaskFile(): initializing (@ {_room.id})");
	
	buffer = undefined;

	static process := function () {
		parent.buffer = nullstars_root().package.load_world_room(parent.id);
		parent.state = WorldRoomState.Filed;
		return WorldTaskStatus.Complete;
	};
}

function WorldTaskParse(_room) : WorldTask(_room, 0) constructor {
	LOG(Log.Note, $"WorldTaskParse(): initializing (@ {_room.id})");
	
	static process := function () {
		ASSERT_NE(parent.buffer, undefined);
		ASSERT(buffer_exists(parent.buffer));
		
		var _buffer := parent.buffer;
		
		var _magic_nullstars := buffer_read(_buffer, buffer_string);
		// todo: proper error reporting
		ASSERT_EQ(_magic_nullstars, "nullstars");
		
		var _magic_number := buffer_read(_buffer, buffer_string);
		ASSERT_EQ(_magic_number, "R");
		
		var _version := buffer_read(_buffer, buffer_u16);
		
		var _width := buffer_read(_buffer, buffer_u32);
		var _height := buffer_read(_buffer, buffer_u32);
		
		var _solid_size := buffer_read(_buffer, buffer_u32);
		
		var _solid_pointer := buffer_tell(_buffer);
		
		parent.buffer_map = {
			version: _version,
			width: _width,
			height: _height,
			solid: {
				pointer: _solid_pointer,
				length: _solid_size,
			},
		};
		
		return WorldTaskStatus.Complete;
	};
	
	static collect := function () {
		return [
			new WorldTaskParseLayer(parent),
		];
	};
}

function WorldTaskParseLayer(_room) : WorldTask(_room, 0) constructor {
	LOG(Log.Note, $"WorldTaskParseLayer(): initializing (@ {_room.id})");
	
	static process := function () {
		ASSERT_NE(parent.buffer_map, undefined);
		
		ASSERT_EQ(parent.layer_solid_base, undefined);
		ASSERT_EQ(parent.layer_solid_tilemap, undefined);
		
		var _buffer := parent.buffer;
		var _map := parent.buffer_map;
		
		var _layer_solid_base := layer_create(0);
		layer_set_visible(_layer_solid_base, false);
		var _layer_solid_tilemap := layer_tilemap_create(
			_layer_solid_base,
			parent.x * TILE_SIZE,
			parent.y * TILE_SIZE,
			ts_debug_tileset,
			parent.width,
			parent.height
		);
		tilemap_set_mask(_layer_solid_tilemap, 0);
		
		var _layer_spike_base := layer_create(0);
		var _layer_spike_tilemap := layer_tilemap_create(
			_layer_spike_base,
			parent.x * TILE_SIZE,
			parent.y * TILE_SIZE,
			ts_spike,
			parent.width,
			parent.height
		);
		
		var _layer_graphic_front_vb := vertex_create_buffer();
		
		parent.layer_solid_base = _layer_solid_base;
		parent.layer_solid_tilemap = _layer_solid_tilemap;
		
		parent.layer_spike_base = _layer_spike_base;
		parent.layer_spike_tilemap = _layer_spike_tilemap;
		
		parent.layer_graphic_front_vb = _layer_graphic_front_vb;
		
		buffer_seek(_buffer, buffer_seek_start, _map.solid.pointer);
		
		for (var i = 0; i < _map.solid.length; i++) {
			var _data := buffer_read(_buffer, buffer_u8);
			
			if _data == 0 {
				// empty tile
			}
			else {
				var _x := i mod _map.width;
				var _y := i div _map.width;
				
				var _kind := (_data & 0b1100_0000) >> 6;
				var _value := _data & 0b0011_1111;
				
				if _kind == 0b00 {
					// solid tile
					tilemap_set(_layer_solid_tilemap, _value << 2, _x, _y);
				}
				else if _kind == 0b01 {
					// spike tile
					ASSERT(0 <= _value && _value <= 3);
					tilemap_set(_layer_spike_tilemap, _value + 1, _x, _y);
				}
				else if _kind == 0b10 {
					tilemap_set(_layer_solid_tilemap, (_value << 2) | 1, _x, _y);
				}
				else {
					ASSERT(false);
				}
			}
		}
		
		var _root := nullstars_root();
		
		var _tiles_sprite := _root.package.get_sprite_tiles();
		var _tiles_uvs := _root.package.get_sprite_tiles_uvs();
		
		var _tex_ture := sprite_get_texture(_tiles_sprite, 0);
		
		var _tex_tw := texture_get_texel_width(_tex_ture);
		var _tex_th := texture_get_texel_height(_tex_ture);
		
		var _rules := _root.world.rules;
		
		vertex_begin(_layer_graphic_front_vb, nullstars_world_get_vertex_format());
		
		var _time = get_timer();
		
		for (var _y = 0; _y < _map.height; _y++) {
			for (var _x = 0; _x < _map.width; _x++) {
				var _current := tilemap_get(_layer_solid_tilemap, _x, _y);
				
				if _current == 0 {
					continue;
				}
				
				var _resolve;
				
				if _current & 1 == 1 {
					_resolve := _rules.collector;
					_resolve.clear();
					_resolve.add((_current >> 2) + 1, 0);
				}
				else {
					_resolve := _rules.run(_layer_solid_tilemap, _x, _y)
				}

				for (var i = 0, _len := _resolve.length; i < _len; i++) {
					var _tile := _resolve.array[i];
					
					var _v_x0 := _tiles_uvs.left + _tile.src_x * _tex_tw * TILE_SIZE;
					var _v_x1 := _v_x0 + _tex_tw * TILE_SIZE;
					var _v_y0 := _tiles_uvs.top + _tile.src_y * _tex_th * TILE_SIZE;
					var _v_y1 := _v_y0 + _tex_th * TILE_SIZE;
				
					var _p_x0 := (_x + _tile.off_y) * TILE_SIZE + irandom_range(_tile.rand_x_min, _tile.rand_x_max);
					var _p_x1 := _p_x0 + TILE_SIZE;
					var _p_y0 := (_y + _tile.off_x) * TILE_SIZE + irandom_range(_tile.rand_y_min, _tile.rand_y_max);
					var _p_y1 := _p_y0 + TILE_SIZE;
				
					vertex_position_3d(_layer_graphic_front_vb, _p_x0, _p_y0, 0);
					vertex_texcoord(_layer_graphic_front_vb, _v_x0, _v_y0);
				
					vertex_position_3d(_layer_graphic_front_vb, _p_x1, _p_y0, 0);
					vertex_texcoord(_layer_graphic_front_vb, _v_x1, _v_y0);
				
					vertex_position_3d(_layer_graphic_front_vb, _p_x0, _p_y1, 0);
					vertex_texcoord(_layer_graphic_front_vb, _v_x0, _v_y1);
				
					vertex_position_3d(_layer_graphic_front_vb, _p_x1, _p_y0, 0);
					vertex_texcoord(_layer_graphic_front_vb, _v_x1, _v_y0);
				
					vertex_position_3d(_layer_graphic_front_vb, _p_x1, _p_y1, 0);
					vertex_texcoord(_layer_graphic_front_vb, _v_x1, _v_y1);
				
					vertex_position_3d(_layer_graphic_front_vb, _p_x0, _p_y1, 0);
					vertex_texcoord(_layer_graphic_front_vb, _v_x0, _v_y1);
				}
			}
		}
		
		show_debug_message((get_timer() - _time) / 1000)
		
		vertex_end(_layer_graphic_front_vb);
		vertex_freeze(_layer_graphic_front_vb);
		
		return WorldTaskStatus.Complete;
	};
}

function nullstars_world_get_vertex_format() {
	static __format = undefined;
	
	if __format == undefined {
		vertex_format_begin();
		
		vertex_format_add_position_3d();
		vertex_format_add_texcoord();
		
		__format := vertex_format_end();
	}
	
	return __format;
}

function nullstars_world_get_test() {
	static __out := {
		"stamps": [
		],
		"rules": [
			{
				"rule": "match",
				"match": {
					"condition": "tileset",
					"tileset": [2],
				},
				"then": {
					"rule": "list",
					"list": [
						{
							"rule": "match",
							"match": { "condition": "class", "class": [7, 4, 5, 25] },
							"then": {
								"rule": "emit",
								"emit": "single",
								"single": {
									"stamp": "choose",
									"choose": [
										{ "stamp": "tile", "src_x": 1, "src_y": 11, "rand_y_max": 1 },
										{ "stamp": "tile", "src_x": 2, "src_y": 11, "rand_y_max": 1 },
									],
								},
							},
						},
						{
							"rule": "match",
							"match": { "condition": "class", "class": [24, 6] },
							"then": {
								"rule": "emit",
								"emit": "single",
								"single": {
									"stamp": "choose",
									"choose": [
										{ "stamp": "tile", "src_x": 0, "src_y": 11 },
									],
								},
							},
						},
						{
							"rule": "match",
							"match": { "condition": "class", "class": [26, 8] },
							"then": {
								"rule": "emit",
								"emit": "single",
								"single": {
									"stamp": "choose",
									"choose": [
										{ "stamp": "tile", "src_x": 3, "src_y": 11 },
									],
								},
							},
						},
					],
				},
			},
			{
				"rule": "emit",
				"emit": "blob",
				"src_x": 0,
				"src_y": 1,
			},
		],
	};
	
	return __out;
}

function nullstars_world_autotile_rules_process_select(_tilemap, _current, _x, _y) {
	var _tile := tilemap_get(_tilemap, _x, _y);
	if _tile == -1 {
		return _current;
	}
	if (_tile & 1) == 1 {
		return 0;
	}
	return _tile >> 2;
}

function WorldAutotileCompiler() constructor {
	
	static compile := function (_json) {
		var _stamps := variable_struct_get(_json, "stamps");
		ASSERT(is_array(_stamps));
		
		var _rules := variable_struct_get(_json, "rules");
		ASSERT(is_array(_rules));
		
		var _pebis_stamps := {};
		
		for (var i = 0, _len := array_length(_stamps); i < _len; i++) {
			var _stamps_v := _stamps[i];
			
			var _stamps_id := variable_struct_get(_stamps_v, "id");
			ASSERT(is_string(_stamps_id));
			
			var _stamps_rule := variable_struct_get(_stamps_v, "rule");
			
			var _stamp := compile_stamp(_stamps_rule);
			
			_pebis_stamps[$ _stamps_id] := _stamp;
		}
		
		var _pebis_rules_array_len := array_length(_rules);
		
		var _pebis_rules_array := array_create(_pebis_rules_array_len);
		
		for (var i = 0; i < _pebis_rules_array_len; i++) {
			_pebis_rules_array[i] = compile_criteria(_rules[i]);
		}
		
		var _pebis_rules_root := method({
			array: _pebis_rules_array,
		}, __nullstars_world_autotile_expr_criteria_list);
		
		return new WorldAutotilePebis(_pebis_stamps, _pebis_rules_root);
	};
	
	static compile_stamp := function (_json) {
		ASSERT(is_struct(_json));
		
		var _json_type := variable_struct_get(_json, "stamp");
		ASSERT(is_string(_json_type));
		
		switch _json_type {
			case "choose": {
				var _choose := variable_struct_get(_json, "choose");
				ASSERT(is_array(_choose));
				
				var _len := array_length(_choose);
				
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_stamp(_choose[i]);
				}
				
				return method({
					array: _array,
				}, __nullstars_world_autotile_expr_stamp_choose);
			}
			
			case "list": {
				var _list := variable_struct_get(_json, "list");
				ASSERT(is_array(_list));
				
				var _len := array_length(_list);
				
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_stamp(_list[i]);
				}
				
				return method({
					array: _array,
				}, __nullstars_world_autotile_expr_stamp_list);
			}
			
			case "tile": {
				var _src_x := variable_struct_get(_json, "src_x");
				ASSERT(is_real(_src_x));
				var _src_y := variable_struct_get(_json, "src_y");
				ASSERT(is_real(_src_y));
			
				var _off_x := variable_struct_get(_json, "off_x") ?? 0;
				ASSERT(is_real(_off_x));
			
				var _off_y := variable_struct_get(_json, "off_y") ?? 0;
				ASSERT(is_real(_off_y));
			
				var _off_z := variable_struct_get(_json, "off_z") ?? 0;
				ASSERT(is_real(_off_z));
			
				var _rand_x_min := variable_struct_get(_json, "rand_x_min") ?? 0;
				ASSERT(is_real(_rand_x_min));
			
				var _rand_x_max := variable_struct_get(_json, "rand_x_max") ?? 0;
				ASSERT(is_real(_rand_x_max));
			
				var _rand_y_min := variable_struct_get(_json, "rand_y_min") ?? 0;
				ASSERT(is_real(_rand_y_min));
			
				var _rand_y_max := variable_struct_get(_json, "rand_y_max") ?? 0;
				ASSERT(is_real(_rand_y_max));
				
				var _stamp := {
					src_x: _src_x,
					src_y: _src_y,
					
					off_x: _off_x,
					off_y: _off_y,
					off_z: _off_z,
					
					rand_x_min: _rand_x_min,
					rand_x_max: _rand_x_max,
					rand_y_min: _rand_y_min,
					rand_y_max: _rand_y_max,
				};
				
				return method({
					stamp: _stamp,
				}, __nullstars_world_autotile_expr_stamp_tile);
			}
			
			default: {
				ASSERT(false, $"unknown type: {_json_type}");
			}
		}
	};
	
	static compile_condition := function (_json) {
		ASSERT(is_struct(_json));
		
		var _type := variable_struct_get(_json, "condition");
		ASSERT(is_string(_type));
		
		switch _type {
			case "all": {
				var _all := variable_struct_get(_json, "all");
				ASSERT(is_array(_all));
				
				var _len := array_length(_all);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_condition(_all[i]);
				}
				
				return method({
					array: _array,
				}, __nullstars_world_autotile_expr_condition_all);
			}
			
			case "any": {
				var _any := variable_struct_get(_json, "any");
				ASSERT(is_array(_any));
				
				var _len := array_length(_any);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_condition(_any[i]);
				}
				
				return method({
					array: _array,
				}, __nullstars_world_autotile_expr_condition_any);
			}
			
			case "none": {
				var _none := variable_struct_get(_json, "none");
				ASSERT(is_array(_none));
				
				var _len := array_length(_none);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_condition(_none[i]);
				}
				
				return method({
					array: _array,
				}, __nullstars_world_autotile_expr_condition_none);
			}
			
			case "tileset": {
				var _tileset := variable_struct_get(_json, "tileset");
				ASSERT(is_array(_tileset));
				
				var _len := array_length(_tileset);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					var _value = _tileset[i];
					ASSERT(is_real(_value));
					_array[i] := _value;
				}
				
				return method({
					array: _array,
				}, __nullstars_world_autotile_expr_condition_tileset);
			}
			
			case "class": {
				var _json_class := variable_struct_get(_json, "class");
				ASSERT(is_array(_json_class));
				
				var _len := array_length(_json_class);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					var _value = _json_class[i];
					ASSERT(is_real(_value));
					_array[i] := _value;
				}
				
				// is it a bad idea to name all of these "array"? yes.
				// is anyone going to stop me? unfortunately, no.
				return method({
					array: _array,
				}, __nullstars_world_autotile_expr_condition_class);
			}
			
			case "noise": {
				var _noise := variable_struct_get(_json, "noise");
				ASSERT(is_real(_noise));
				
				ASSERT(false);
			}
			
			default: {
				ASSERT(false, $"unknown type: {_type}");
			}
		}
	};
	
	static compile_criteria := function (_json) {
		ASSERT(is_struct(_json));

		var _json_type := variable_struct_get(_json, "rule");
		ASSERT(is_string(_json_type));
		
		switch _json_type {
			case "emit": {
				var _json_emit := variable_struct_get(_json, "emit");
				ASSERT(is_string(_json_emit));
				
				switch _json_emit {
					case "blob": {
						var _json_src_x := variable_struct_get(_json, "src_x");
						ASSERT(is_real(_json_src_x));
						
						var _json_src_y := variable_struct_get(_json, "src_y");
						ASSERT(is_real(_json_src_y));
						
						return method({
							src_x: _json_src_x,
							src_y: _json_src_y,
						}, __nullstars_world_autotile_expr_criteria_emit_blob);
					}
					
					case "stamp": {
						var _json_stamp := variable_struct_get(_json, "stamp");
						ASSERT(is_string(_json_stamp));
						
						return method({
							stamp: _json_stamp,
						}, __nullstars_world_autotile_expr_criteria_emit_stamp);
					}
					
					case "single": {
						var _json_single := variable_struct_get(_json, "single");
						
						var _stamp := compile_stamp(_json_single);
						
						return method({
							stamp: _stamp,
						}, __nullstars_world_autotile_expr_criteria_emit_single)
					}
					
					default: {
						ASSERT(false, $"unknown emitter: {_json_emit}");
					}
				}
			}
			
			case "overlay": {
				var _json_overlay := variable_struct_get(_json, "overlay");
				
				var _overlay := compile_criteria(_json_overlay);
				
				var _json_with := variable_struct_get(_json, "with") ?? false;
				ASSERT(is_bool(_json_with));
				
				return method({
					overlay: _overlay,
					into: _json_with,
				}, __nullstars_world_autotile_expr_criteria_overlay);
			}
			
			case "list": {
				var _json_list := variable_struct_get(_json, "list");
				ASSERT(is_array(_json_list));
				
				var _len := array_length(_json_list);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_criteria(_json_list[i]);
				}
				
				return method({
					array: _array,
				}, __nullstars_world_autotile_expr_criteria_list);
			}
			
			case "choose": {
				var _json_choose := variable_struct_get(_json, "choose");
				ASSERT(is_array(_json_choose));
				
				var _len := array_length(_json_choose);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_criteria(_json_choose[i]);
				}
				
				return method({
					array: _array,
				}, __nullstars_world_autotile_expr_criteria_choose);
			}
			
			case "match": {
				var _json_match := variable_struct_get(_json, "match");
				
				var _match := compile_condition(_json_match);
				
				var _json_then := variable_struct_get(_json, "then");
				
				var _then := compile_criteria(_json_then);
				
				var _json_else := variable_struct_get(_json, "else");
				
				if _json_else != undefined {
					var _else := compile_criteria(_json_else);
					
					return method({
						match: _match,
						branch_then: _then,
						branch_else: _else,
					}, __nullstars_world_autotile_expr_criteria_match_else);
				}
				else {
					return method({
						match: _match,
						branch_then: _then,
					}, __nullstars_world_autotile_expr_criteria_match);
				}
			}
			
			default: {
				ASSERT(false, $"unknown type: {_json_type}");
			}
		}
	};
}

/**
@arg {struct} _stamps
@arg {function} _root
*/
function WorldAutotilePebis(_stamps, _root) constructor {
	stamps := _stamps;
	root := _root;
	
	tilemap = undefined;
	x = 0;
	y = 0;
	
	collector := new WorldAutotileStampCollector();
	
	/**
	@arg {id.Tilemap} _tilemap
	@arg {real} _x
	@arg {real} _y
	*/
	static run := function (_tilemap, _x, _y) {
		collector.clear();
		
		tilemap = _tilemap;
		x = _x;
		y = _y;
		
		root(self);
		
		return collector;
	};
}

/*
there are three types of nodes we are working with here:

stamp
	this describes what tiles to place down with what properties. they otherwise
	don't have any way of controlling anything but that basic declarative structure.
	their functions do not return anything.

criteria
	akin to control flow, this describes the shape of which the logic will flow.
	their functions return `true` to indicate that no further processing should occur.
	
condition
	akin to boolean operations, this allows for checking for various conditions within
	certain criteria.
	their functions return `true` if they match, and `false` if they don't.
*/

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_criteria_emit_blob(_root) {
	var _tilemap := _root.tilemap;
	var _x := _root.x;
	var _y := _root.y;
	
	var _current := tilemap_get(_tilemap, _x, _y) >> 2;
	
	var _topleft :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x - 1, _y - 1);
	var _top :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x, _y - 1);
	var _topright :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x + 1, _y - 1);
	var _left :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x - 1, _y);
	var _right :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x + 1, _y);
	var _bottomleft :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x - 1, _y + 1);
	var _bottom :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x, _y + 1);
	var _bottomright :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x + 1, _y + 1);
	
	var _t_i := nullstars_world_autotile_map(
		_topleft != 0,
		_top != 0,
		_topright != 0,
		_left != 0,
		_right != 0,
		_bottomleft != 0,
		_bottom != 0,
		_bottomright != 0
	);
	
	var _t_s := nullstars_world_autotile_sheet()[_t_i];
	
	var _t_t := nullstars_world_autotile_format_blob(_t_s);
	
	_root.collector.add(src_x + _t_t.x, src_y + _t_t.y);
	
	return true;
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_criteria_emit_single(_root) {
	stamp(_root);
	
	return true;
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_criteria_emit_stamp(_root) {
	_root.stamps[$ stamp](_root)
	
	return true;
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_criteria_match(_root) {
	if match(_root) {
		return branch_then(_root);
	}
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_criteria_match_else(_root) {
	if match(_root) {
		return branch_then(_root);
	}
	else {
		return branch_else(_root);
	}
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_criteria_list(_root) {
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if array[i](_root) {
			return true;
		}
	}
	return false;
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_criteria_choose(_root) {
	var _len := array_length(array);
	if _len != 0 {
		return array[irandom(_len - 1)](_root);
	}
	return false;
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_criteria_overlay(_root) {
	overlay(_root);
	return into;
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_condition_all(_root) {
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if !array[i](_root) {
			return false;
		}
	}
	return true;
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_condition_any(_root) {
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if array[i](_root) {
			return true;
		}
	}
	return false;
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_condition_none(_root) {
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if array[i](_root) {
			return false;
		}
	}
	return true;
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_condition_class(_root) {
	var _tilemap := _root.tilemap;
	var _x := _root.x;
	var _y := _root.y;
	
	var _current := tilemap_get(_tilemap, _x, _y) >> 2;
	
	var _topleft :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x - 1, _y - 1);
	var _top :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x, _y - 1);
	var _topright :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x + 1, _y - 1);
	var _left :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x - 1, _y);
	var _right :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x + 1, _y);
	var _bottomleft :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x - 1, _y + 1);
	var _bottom :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x, _y + 1);
	var _bottomright :=
		nullstars_world_autotile_rules_process_select(_tilemap, _current, _x + 1, _y + 1);
	
	var _t_i := nullstars_world_autotile_map(
		_topleft != 0,
		_top != 0,
		_topright != 0,
		_left != 0,
		_right != 0,
		_bottomleft != 0,
		_bottom != 0,
		_bottomright != 0
	);
	
	var _t_s := nullstars_world_autotile_sheet_match()[_t_i];
	
	// show_debug_message("{0} {1} {2} {3}", _t_s, _t_i, _current, array);
	
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if array[i] == _t_s {
			return true;
		}
	}
	
	return false;
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_condition_tileset(_root) {
	var _current := tilemap_get(_root.tilemap, _root.x, _root.y) >> 2;

	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if array[i] == _current {
			return true;
		}
	}
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_stamp_choose(_root) {
	var _len := array_length(array);
	if _len != 0 {
		array[irandom(_len - 1)](_root);
	}
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_stamp_list(_root) {
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		array[i](_root);
	}
}

/**
@arg {struct.WorldAutotilePebis} _root
*/
function __nullstars_world_autotile_expr_stamp_tile(_root) {
	_root.collector.add(
		stamp.src_x,
		stamp.src_y,
		stamp.off_x,
		stamp.off_y,
		stamp.off_z,
		stamp.rand_x_min,
		stamp.rand_x_max,
		stamp.rand_y_min,
		stamp.rand_y_max
	);
}

function WorldAutotileStampCollector() constructor {
	array := [];
	length = 0;
	
	static clear := function () {
		length = 0;
	};
	
	static add := function (
		_src_x,
		_src_y,
		_off_x = 0,
		_off_y = 0,
		_off_z = 0,
		_rand_x_min = 0,
		_rand_x_max = 0,
		_rand_y_min = 0,
		_rand_y_max = 0,
	) {
		if array_length(array) == length {
			array_push(array, {
				src_x: 0,
				src_y: 0,
				
				off_x: 0,
				off_y: 0,
				off_z: 0,
				
				rand_x_min: 0,
				rand_x_max: 0,
				rand_y_min: 0,
				rand_y_max: 0,
			});
		}
		
		var _cache := array[length++];
		
		_cache.src_x = _src_x;
		_cache.src_y = _src_y;
		
		_cache.off_x = _off_x;
		_cache.off_y = _off_y;
		_cache.off_z = _off_z;
		
		_cache.rand_x_min = _rand_x_min;
		_cache.rand_x_max = _rand_x_max;
		_cache.rand_y_min = _rand_y_min;
		_cache.rand_y_max = _rand_y_max;
	};
}

/**
@arg {real} _width
@arg {real} _height
@arg {real} [_seed]
*/
function nullstars_world_autotile_noise_gen(_width, _height, _seed = undefined) {
	var _length := _width * _height;
	var _array := array_create(_length);
	
	var _seed_prev;
	if _seed != undefined {
		_seed_prev := random_get_seed();
		// random_set_seed(_seed, true);
	}
	
	for (var i = 0; i < _length; i++) {
		_array[i] = random(1);
	}
	
	if _seed != undefined {
		// random_set_seed(_seed_prev, true);
	}
	
	return {
		data: _array,
		width: _width,
		height: _height,
	};
}

/**
returns a lookup table of blob-style tile matches. this array should not be
indexed by anything but the output of `nullstars_world_autotile_map()`.
*/
function nullstars_world_autotile_sheet() {
	static __array = undefined;
	
	/*
	   1   2   4
	   8   ?  16
	  32  64 128
	
	00000001  00000010  00000100
	
	00001000  xxxxxxxx  00010000
	
	00100000  01000000  10000000
	*/
	
	if __array == undefined {
		// fill with undefined, in the hope that retrieving an invalid value results in a crash.
		__array := array_create(256, undefined);
		
		// o o o
		// o : o
		// o o o
		__array[0b0000_0000] := 0;
		
		// o = o
		// o : o
		// o o o
		__array[0b0000_0010] := 1;
		
		// o o o
		// = : o
		// o o o
		__array[0b0000_1000] := 2;
		
		// o = o
		// = : o
		// o o o
		__array[0b0000_1010] := 3;
		
		// = = o
		// = : o
		// o o o
		__array[0b0000_1011] := 4;
		
		// o o o
		// o : =
		// o o o
		__array[0b0001_0000] := 5;
		
		// o = o
		// o : =
		// o o o
		__array[0b0001_0010] := 6;
		
		// o = =
		// o : =
		// o o o
		__array[0b0001_0110] := 7;
		
		// o o o
		// = : =
		// o o o
		__array[0b0001_1000] := 8;
		
		// o = o
		// = : =
		// o o o
		__array[0b0001_1010] := 9;
		
		// = = o
		// = : =
		// o o o
		__array[0b0001_1011] := 10;
		
		// o = =
		// = : =
		// o o o
		__array[0b0001_1110] := 11;
		
		// = = =
		// = : =
		// o o o
		__array[0b0001_1111] := 12;
		
		// o o o
		// o : o
		// o = o
		__array[0b0100_0000] := 13;
		
		// o = o
		// o : o
		// o = o
		__array[0b0100_0010] := 14;
		
		// o o o
		// = : o
		// o = o
		__array[0b0100_1000] := 15;
		
		// o = o
		// = : o
		// o = o
		__array[0b0100_1010] := 16;
		
		// = = o
		// = : o
		// o = o
		__array[0b0100_1011] := 17;
		
		// o o o
		// o : =
		// o = o
		__array[0b0101_0000] := 18;
		
		// o = o
		// o : =
		// o = o
		__array[0b0101_0010] := 19;
		
		// o = =
		// o : =
		// o = o
		__array[0b0101_0110] := 20;
		
		// o o o
		// = : =
		// o = o
		__array[0b0101_1000] := 21;
		
		// o = o
		// = : =
		// o = o
		__array[0b0101_1010] := 22;
		
		// = = o
		// = : =
		// o = o
		__array[0b0101_1011] := 23;
		
		// o = =
		// = : =
		// o = o
		__array[0b0101_1110] := 24;
		
		// = = =
		// = : =
		// o = o
		__array[0b0101_1111] := 25;
		
		// o o o
		// = : o
		// = = o
		__array[0b0110_1000] := 26;
		
		// o = o
		// = : o
		// = = o
		__array[0b0110_1010] := 27;
		
		// = = o
		// = : o
		// = = o
		__array[0b0110_1011] := 28;
		
		// o o o
		// = : =
		// = = o
		__array[0b0111_1000] := 29;
		
		// o = o
		// = : =
		// = = o
		__array[0b0111_1010] := 30;
		
		// = = o
		// = : =
		// = = o
		__array[0b0111_1011] := 31;
		
		// o = =
		// = : =
		// = = o
		__array[0b0111_1110] := 32;
		
		// = = =
		// = : =
		// = = o
		__array[0b0111_1111] := 33;
		
		// o o o
		// o : =
		// o = =
		__array[0b1101_0000] := 34;
		
		// o = o
		// o : =
		// o = =
		__array[0b1101_0010] := 35;
		
		// o = =
		// o : =
		// o = =
		__array[0b1101_0110] := 36;
		
		// o o o
		// = : =
		// o = =
		__array[0b1101_1000] := 37;
		
		// o = o
		// = : =
		// o = =
		__array[0b1101_1010] := 38;
		
		// = = o
		// = : =
		// o = =
		__array[0b1101_1011] := 39;
		
		// o = =
		// = : =
		// o = =
		__array[0b1101_1110] := 40;
		
		// = = =
		// = : =
		// o = =
		__array[0b1101_1111] := 41;
		
		// o o o
		// = : =
		// = = =
		__array[0b1111_1000] := 42;
		
		// o = o
		// = : =
		// = = =
		__array[0b1111_1010] := 43;
		
		// = = o
		// = : =
		// = = =
		__array[0b1111_1011] := 44;
		
		// o = =
		// = : =
		// = = =
		__array[0b1111_1110] := 45;
		
		// = = =
		// = : =
		// = = =
		__array[0b1111_1111] := 46;
	}
	
	return __array;
}

/**
returns a lookup table of tile matches, used in the match json api
*/
function nullstars_world_autotile_sheet_match() {
	static __array = undefined;
	
	/*
	   1   2   4
	   8   ?  16
	  32  64 128
	
	00000001  00000010  00000100
	
	00001000  xxxxxxxx  00010000
	
	00100000  01000000  10000000
	*/
	
	if __array == undefined {
		// fill with undefined, in the hope that retrieving an invalid value results in a crash.
		__array := array_create(256, undefined);
		
		// o o o
		// o : o
		// o o o
		__array[0b0000_0000] := 3;
		
		// o = o
		// o : o
		// o o o
		__array[0b0000_0010] := 21;
		
		// o o o
		// = : o
		// o o o
		__array[0b0000_1000] := 2;
		
		// o = o
		// = : o
		// o o o
		__array[0b0000_1010] := 38;
		
		// = = o
		// = : o
		// o o o
		__array[0b0000_1011] := 20;
		
		// o o o
		// o : =
		// o o o
		__array[0b0001_0000] := 0;
		
		// o = o
		// o : =
		// o o o
		__array[0b0001_0010] := 36;
		
		// o = =
		// o : =
		// o o o
		__array[0b0001_0110] := 18;
		
		// o o o
		// = : =
		// o o o
		__array[0b0001_1000] := 1;
		
		// o = o
		// = : =
		// o o o
		__array[0b0001_1010] := 37;
		
		// = = o
		// = : =
		// o o o
		__array[0b0001_1011] := 10;
		
		// o = =
		// = : =
		// o o o
		__array[0b0001_1110] := 11;
		
		// = = =
		// = : =
		// o o o
		__array[0b0001_1111] := 19;
		
		// o o o
		// o : o
		// o = o
		__array[0b0100_0000] := 9;
		
		// o = o
		// o : o
		// o = o
		__array[0b0100_0010] := 15;
		
		// o o o
		// = : o
		// o = o
		__array[0b0100_1000] := 26;
		
		// o = o
		// = : o
		// o = o
		__array[0b0100_1010] := 32;
		
		// = = o
		// = : o
		// o = o
		__array[0b0100_1011] := 17;
		
		// o o o
		// o : =
		// o = o
		__array[0b0101_0000] := 24;
		
		// o = o
		// o : =
		// o = o
		__array[0b0101_0010] := 30;
		
		// o = =
		// o : =
		// o = o
		__array[0b0101_0110] := 16;
		
		// o o o
		// = : =
		// o = o
		__array[0b0101_1000] := 25;
		
		// o = o
		// = : =
		// o = o
		__array[0b0101_1010] := 31;
		
		// = = o
		// = : =
		// o = o
		__array[0b0101_1011] := 44;
		
		// o = =
		// = : =
		// o = o
		__array[0b0101_1110] := 45;
		
		// = = =
		// = : =
		// o = o
		__array[0b0101_1111] := 28;
		
		// o o o
		// = : o
		// = = o
		__array[0b0110_1000] := 8;
		
		// o = o
		// = : o
		// = = o
		__array[0b0110_1010] := 23;
		
		// = = o
		// = : o
		// = = o
		__array[0b0110_1011] := 14;
		
		// o o o
		// = : =
		// = = o
		__array[0b0111_1000] := 4;
		
		// o = o
		// = : =
		// = = o
		__array[0b0111_1010] := 46;
		
		// = = o
		// = : =
		// = = o
		__array[0b0111_1011] := 33;
		
		// o = =
		// = : =
		// = = o
		__array[0b0111_1110] := 43;
		
		// = = =
		// = : =
		// = = o
		__array[0b0111_1111] := 27;
		
		// o o o
		// o : =
		// o = =
		__array[0b1101_0000] := 6;
		
		// o = o
		// o : =
		// o = =
		__array[0b1101_0010] := 22;
		
		// o = =
		// o : =
		// o = =
		__array[0b1101_0110] := 12;
		
		// o o o
		// = : =
		// o = =
		__array[0b1101_1000] := 5;
		
		// o = o
		// = : =
		// o = =
		__array[0b1101_1010] := 47;
		
		// = = o
		// = : =
		// o = =
		__array[0b1101_1011] := 42;
		
		// o = =
		// = : =
		// o = =
		__array[0b1101_1110] := 35;
		
		// = = =
		// = : =
		// o = =
		__array[0b1101_1111] := 29;
		
		// o o o
		// = : =
		// = = =
		__array[0b1111_1000] := 7;
		
		// o = o
		// = : =
		// = = =
		__array[0b1111_1010] := 40;
		
		// = = o
		// = : =
		// = = =
		__array[0b1111_1011] := 39;
		
		// o = =
		// = : =
		// = = =
		__array[0b1111_1110] := 41;
		
		// = = =
		// = : =
		// = = =
		__array[0b1111_1111] := 3;
	}
	
	return __array;
}

/**
@arg {bool} _topleft
@arg {bool} _top
@arg {bool} _topright
@arg {bool} _left
@arg {bool} _right
@arg {bool} _bottomleft
@arg {bool} _bottom
@arg {bool} _bottomright
*/
function nullstars_world_autotile_map(_topleft, _top, _topright, _left, _right, _bottomleft, _bottom, _bottomright) {
	if !_left || !_top {
		_topleft = false;
	}
	if !_left || !_bottom {
		_bottomleft = false;
	}
	if !_right || !_top {
		_topright = false;
	}
	if !_right || !_bottom {
		_bottomright = false;
	}
	
	var _index =
		(+_topleft) +
		(+_top << 1) +
		(+_topright << 2) +
		(+_left << 3) +
		(+_right << 4) +
		(+_bottomleft << 5) +
		(+_bottom << 6) +
		(+_bottomright << 7);
	
	return _index;
}

function nullstars_world_autotile_format_blob(_id) {
	static __array = undefined;
	
	if __array == undefined {
		__array := array_create(48);
		
		__array[0] := { x: 3, y: 0 };
		
		__array[1] := { x: 3, y: 3 };
		
		__array[2] := { x: 2, y: 0 };
		
		__array[3] := { x: 2, y: 6 };
		
		__array[4] := { x: 2, y: 3 };
		
		__array[5] := { x: 0, y: 0 };
		
		__array[6] := { x: 0, y: 6 };
		
		__array[7] := { x: 0, y: 3 };
		
		__array[8] := { x: 1, y: 0 };
		
		__array[9] := { x: 1, y: 6 };
		
		__array[10] := { x: 4, y: 1 };
		
		__array[11] := { x: 5, y: 1 };
		
		__array[12] := { x: 1, y: 3 };
		
		__array[13] := { x: 3, y: 1 };
		
		__array[14] := { x: 3, y: 2 };
		
		__array[15] := { x: 2, y: 4 };
		
		__array[16] := { x: 2, y: 5 };
		
		__array[17] := { x: 5, y: 2 };
		
		__array[18] := { x: 0, y: 4 };
		
		__array[19] := { x: 0, y: 5 };
		
		__array[20] := { x: 4, y: 2 };
		
		__array[21] := { x: 1, y: 4 };
		
		__array[22] := { x: 1, y: 5 };
		
		__array[23] := { x: 2, y: 7 };
		
		__array[24] := { x: 3, y: 7 };
		
		__array[25] := { x: 4, y: 4 };
		
		__array[26] := { x: 2, y: 1 };
		
		__array[27] := { x: 5, y: 3 };
		
		__array[28] := { x: 2, y: 2 };
		
		__array[29] := { x: 4, y: 0 };
		
		__array[30] := { x: 4, y: 7 };
		
		__array[31] := { x: 3, y: 5 };
		
		__array[32] := { x: 1, y: 7 };
		
		__array[33] := { x: 3, y: 4 };
		
		__array[34] := { x: 0, y: 1 };
		
		__array[35] := { x: 4, y: 3 };
		
		__array[36] := { x: 0, y: 2 };
		
		__array[37] := { x: 5, y: 0 };
		
		__array[38] := { x: 5, y: 7 };
		
		__array[39] := { x: 0, y: 7 };
		
		__array[40] := { x: 5, y: 5 };
		
		__array[41] := { x: 5, y: 4 };
		
		__array[42] := { x: 1, y: 1 };
		
		__array[43] := { x: 4, y: 6 };
		
		__array[44] := { x: 3, y: 6 };
		
		__array[45] := { x: 5, y: 6 };
		
		__array[46] := { x: 4, y: 5 };
	}
	
	return __array[_id];
}

