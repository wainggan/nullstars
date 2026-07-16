enum ns_level_RoomComponentState {
	Idle,
	Working,
	Complete,
	Cleaning,
}

enum ns_level_RoomComponentStatus {
	Running,
	Waiting,
	Complete,
}

function ns_level_RoomComponentsList() constructor {
	static component_file := new ns_level_RoomComponentFile();
	static component_header := new ns_level_RoomComponentHeader();
	static component_parse_setup := new ns_level_RoomComponentParseSetup();
	static component_parse_collision := new ns_level_RoomComponentParseCollision();
	static component_autotile := new ns_level_RoomComponentAutotile();
	static component_parse_entity := new ns_level_RoomComponentParseEntity();
	
	static list := [
		component_file,
		component_header,
		component_parse_setup,
		component_parse_collision,
		component_autotile,
		component_parse_entity,
	];
	
	static phase_file := [
		component_file,
		component_header,
		component_parse_setup,
		component_parse_collision,
		component_autotile,
		component_parse_entity,
	];
}

function ns_level_component() {
	static __out := new ns_level_RoomComponentsList();
	return __out;
}

#region RoomComponent

/**
@arg {string} _name
*/
function ns_level_RoomComponent(_name) constructor {
	name := _name;
	__var_state_name := $"{_name}##state";
	__var_state_hash := variable_get_hash(__var_state_name);
	
	/**
	@arg {struct.ns_level_Room} _room
	*/
	static fn_work_init := function (_room) {};
	
	/**
	@arg {struct.ns_level_Room} _room
	@return {enum.ns_level_RoomComponentStatus}
	*/
	static fn_work_tick := function (_room) {
		return ns_level_RoomComponentStatus.Complete;
	};
	
	/**
	@arg {struct.ns_level_Room} _room
	*/
	static fn_clean_init := function (_room) {};
	
	/**
	@arg {struct.ns_level_Room} _room
	@return {enum.ns_level_RoomComponentStatus}
	*/
	static fn_clean_tick := function (_room) {
		return ns_level_RoomComponentStatus.Complete;
	};

	/**
	@arg {string} _name
	@return {real}
	*/
	static util_var_hash := function (_name, _prefix = self.name) {
		return variable_get_hash($"{_prefix}_{_name}");
	};
	
	/**
	@arg {struct.ns_level_Room} _room
	@arg {real} _hash
	*/
	static util_get := function (_room, _hash) {
		return struct_get_from_hash(_room.resources, _hash);
	};
	
	/**
	@arg {struct.ns_level_Room} _room
	@arg {real} _hash
	@return {bool}
	*/
	static util_exists := function (_room, _hash) {
		return struct_exists_from_hash(_room.resources, _hash);
	};
	
	/**
	@arg {struct.ns_level_Room} _room
	@arg {real} _hash
	@arg {any} _value
	*/
	static util_set := function (_room, _hash, _value) {
		struct_set_from_hash(_room.resources, _hash, _value);
	};
	
	/**
	@arg {struct.ns_level_Room} _room
	@return {enum.ns_level_RoomComponentState}
	*/
	static state_get := function (_room) {
		var _state := struct_get_from_hash(_room.resources, self.__var_state_hash);
		ASSERT_NE_DEBUG(_state, undefined);
		return _state;
	};
	
	/**
	@arg {struct.ns_level_Room} _room
	@arg {enum.ns_level_RoomComponentState} _state
	*/
	static state_set := function (_room, _state) {
		struct_set_from_hash(_room.resources, self.__var_state_hash, _state);
	};
	
	/**
	@arg {struct.ns_level_Room} _room
	*/
	static init := function (_room) {
		self.state_set(_room, ns_level_RoomComponentState.Idle);
	};
	
	/**
	@arg {bool} _load
	@arg {struct.ns_level_Room} _room
	@arg {struct.ns_level_Budget} _budget
	@return {enum.ns_level_RoomComponentState}
	*/
	static tick := function (_load, _room, _budget) {
		var _state := self.state_get(_room);
		
		if _load {
			if _state == ns_level_RoomComponentState.Idle {
				self.state_set(_room, ns_level_RoomComponentState.Working);
				self.fn_work_init(_room);
			}
		}
		else {
			if _state == ns_level_RoomComponentState.Complete {
				self.state_set(_room, ns_level_RoomComponentState.Cleaning);
				self.fn_clean_init(_room);
			}
		}
		
		_state := self.state_get(_room);
		
		if _state == ns_level_RoomComponentState.Working {
			var _out = self.fn_work_tick(_room);
			_budget.tick();
			
			if _out == ns_level_RoomComponentStatus.Complete {
				self.state_set(_room, ns_level_RoomComponentState.Complete);
			}
			
			return _out;
		}
		else if _state == ns_level_RoomComponentState.Cleaning {
			var _out := self.fn_clean_tick(_room);
			_budget.tick();
			
			if _out == ns_level_RoomComponentStatus.Complete {
				self.state_set(_room, ns_level_RoomComponentState.Idle);
			}
			
			return _out;
		}
		
		return ns_level_RoomComponentStatus.Complete;
	};
}

#endregion

#region RoomComponent implementations

function ns_level_RoomComponentFile() : ns_level_RoomComponent("file") constructor {
	var_buffer_name := $"{name}_buffer";

	static get_buffer := function (_room) {
		return _room.resources[$ self.var_buffer_name];
	};
	
	static fn_work_init := function (_room) {
		LOG(Log.Note, $"ns_level_RoomComponentFile(): initializing (@ {_room.id})");
		_room.resources[$ var_buffer_name] = undefined;
	};
	
	static fn_work_tick := function (_room) {
		LOG(Log.Note, $"ns_level_RoomComponentFile(): tick (@ {_room.id})");
		if _room.resources[$ var_buffer_name] == undefined {
			_room.resources[$ var_buffer_name] = ns_root().package.load_world_room(_room.id);
		}
		return ns_level_RoomComponentStatus.Complete;
	};
	
	static fn_clean_init := function (_room) {
		
	};
	
	static fn_clean_tick := function (_room) {
		buffer_delete(_room.resources[$ var_buffer_name]);
		return ns_level_RoomComponentStatus.Complete;
	};
}

function ns_level_RoomComponentHeader() : ns_level_RoomComponent("header") constructor {
	var_buffer_map_name := $"{name}_buffer_map";

	static get_buffer_map := function (_room) {
		return _room.resources[$ self.var_buffer_map_name];
	};
	
	static fn_work_init := function (_room) {
		LOG(Log.Note, $"ns_level_RoomComponentHeader(): initializing (@ {_room.id})");
		_room.resources[$ self.var_buffer_map_name] = undefined;
	};
	
	static fn_work_tick := function (_room) {
		if _room.resources[$ self.var_buffer_map_name] == undefined {
			var _buffer := ns_level_component().component_file.get_buffer(_room);
			ASSERT_NE(_buffer, undefined);
			ASSERT(buffer_exists(_buffer));
				
			buffer_seek(_buffer, buffer_seek_start, 0);
		
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
			
			buffer_seek(_buffer, buffer_seek_relative, _solid_size); // tiles are 1 bit
			
			var _entity_size := buffer_read(_buffer, buffer_u32);
			
			var _entity_pointer := buffer_tell(_buffer);
		
			_room.resources[$ self.var_buffer_map_name] = {
				version: _version,
				width: _width,
				height: _height,
				solid: {
					pointer: _solid_pointer,
					length: _solid_size,
				},
				entity: {
					pointer: _entity_pointer,
					length: _entity_size,
				},
			};
		}
		
		return ns_level_RoomComponentStatus.Complete;
	};
	
	static fn_clean_init := function (_room) {
		
	};
	
	static fn_clean_tick := function (_room) {
		delete _room.resources[$ self.var_buffer_map_name];
		return ns_level_RoomComponentStatus.Complete;
	};
}

function ns_level_RoomComponentParseSetup() : ns_level_RoomComponent("parse_setup") constructor {
	static fn_work_init := function (_room) {};
	
	static fn_work_tick := function (_room) {
		LOG(Log.Note, $"ns_level_RoomComponentParseSetup(): initializing (@ {_room.id})");
		
		ASSERT_EQ(_room.layer_solid_base, undefined);
		ASSERT_EQ(_room.layer_solid_tilemap, undefined);
		
		var _layer_solid_base := layer_create(0);
		layer_set_visible(_layer_solid_base, false);
		var _layer_solid_tilemap := layer_tilemap_create(
			_layer_solid_base,
			_room.x * TILE_SIZE,
			_room.y * TILE_SIZE,
			ts_debug_tileset,
			_room.width,
			_room.height
		);
		tilemap_set_mask(_layer_solid_tilemap, 0);
		
		var _layer_spike_base := layer_create(0);
		var _layer_spike_tilemap := layer_tilemap_create(
			_layer_spike_base,
			_room.x * TILE_SIZE,
			_room.y * TILE_SIZE,
			ts_spike,
			_room.width,
			_room.height
		);
		
		var _layer_graphic_front_vb := vertex_create_buffer();
		
		_room.layer_solid_base = _layer_solid_base;
		_room.layer_solid_tilemap = _layer_solid_tilemap;
		
		_room.layer_spike_base = _layer_spike_base;
		_room.layer_spike_tilemap = _layer_spike_tilemap;
		
		// _room.layer_graphic_front_vb = _layer_graphic_front_vb;
		
		return ns_level_RoomComponentStatus.Complete;
	};
	
	static fn_clean_init := function (_room) {};
	
	// static fn_clean_tick := function (_room) {};
}

function ns_level_RoomComponentParseCollision() : ns_level_RoomComponent("parse_collision") constructor {
	static fn_work_init := function (_room) {
		LOG(Log.Note, $"ns_level_RoomComponentParseCollision(): initializing (@ {_room.id})");
	};
	
	static fn_work_tick := function (_room) {
		var _buffer := ns_level_component().component_file.get_buffer(_room);
		var _map := ns_level_component().component_header.get_buffer_map(_room);
		
		ASSERT_NE_DEBUG(_buffer, undefined);
		ASSERT_NE_DEBUG(_map, undefined);
		
		var _layer_solid_tilemap = _room.layer_solid_tilemap;
		var _layer_spike_tilemap = _room.layer_spike_tilemap;
		
		ASSERT_NE_DEBUG(_layer_solid_tilemap, undefined);
		ASSERT_NE_DEBUG(_layer_spike_tilemap, undefined);
		
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
		
		return ns_level_RoomComponentStatus.Complete;
	};
	
	static fn_clean_init := function (_room) {};
	
	// static fn_clean_tick := function (_room) {};
}

function ns_level_RoomComponentAutotile() : ns_level_RoomComponent("autotile") constructor {
	// var_buffer_name := $"{name}_buffer";
	
	var_state := self.util_var_hash("state");
	
	static fn_work_init := function (_room) {
		LOG(Log.Note, $"ns_level_RoomComponentAutotile(): initializing (@ {_room.id})");
		
		if !self.util_exists(_room, self.var_state) {
			self.util_set(_room, self.var_state, {});
		}
		
		var _state := self.util_get(_room, self.var_state);
		
		_state.vb := vertex_create_buffer();
		vertex_begin(_state.vb, ns_level_get_vertex_format());
		_state.y := 0;
	};
	
	static fn_work_tick := function (_room) {
		var _map := ns_level_component().component_header.get_buffer_map(_room);
		
		ASSERT_NE_DEBUG(_map, undefined);
		
		var _layer_solid_tilemap := _room.layer_solid_tilemap;
		
		ASSERT_NE_DEBUG(_layer_solid_tilemap, undefined);
		
		var _root := ns_root();
		
		var _tiles_sprite := _root.package.get_sprite_tiles();
		var _tiles_uvs := _root.package.get_sprite_tiles_uvs();
		
		var _tex_ture := sprite_get_texture(_tiles_sprite, 0);
		
		var _tex_tw := texture_get_texel_width(_tex_ture);
		var _tex_th := texture_get_texel_height(_tex_ture);
		
		var _rules := _root.world.rules;
		
		var _state := self.util_get(_room, self.var_state);
		
		var _layer_graphic_front_vb := _state.vb;
		var _y = _state.y;
		var _total = 1;
		
		for (; _y < _map.height; _y++) {
			if _total-- <= 0 {
				break;
			}
			
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
		
		_state.y = _y;
		
		if _y < _map.height {
			return ns_level_RoomComponentStatus.Running;
		}
		else {
			vertex_end(_layer_graphic_front_vb);
			vertex_freeze(_layer_graphic_front_vb);
			
			_room.layer_graphic_front_vb = _layer_graphic_front_vb;
		
			return ns_level_RoomComponentStatus.Complete;
		}
	};
	
	static fn_clean_init := function (_room) {
		
	};
	
	static fn_clean_tick := function (_room) {
		return ns_level_RoomComponentStatus.Complete;
	};
}

function ns_level_RoomComponentParseEntity() : ns_level_RoomComponent("parse_entity") constructor {
	static fn_work_init := function (_room) {
		
	};
	
	static fn_work_tick := function (_room) {
		if _room.resource_entity_data == undefined {
			var _buffer := ns_level_component().component_file.get_buffer(_room);
			var _map := ns_level_component().component_header.get_buffer_map(_room);
			
			ASSERT_NE_DEBUG(_buffer, undefined);
			ASSERT_NE_DEBUG(_map, undefined);
			
			buffer_seek(_buffer, buffer_seek_start, _map.entity.pointer);
			
			_room.resource_entity_data := [];
			
			for (var i = 0, _len := _map.entity.length; i < _len; i++) {
				var _entity_name := buffer_read(_buffer, buffer_string);
				var _entity_x := buffer_read(_buffer, buffer_s32);
				var _entity_y := buffer_read(_buffer, buffer_s32);
				
				var _entity_object := ns_object_lut_name()[$ _entity_name];
				ASSERT_NE(_entity_object, undefined, "object does not exist");
				
				array_push(_room.resource_entity_data, {
					name: _entity_name,
					object: _entity_object,
					x: _entity_x,
					y: _entity_y,
				});
			}
		}
		
		show_debug_message(_room.resource_entity_data);
		
		return ns_level_RoomComponentStatus.Complete;
	};
}

function ns_level_get_vertex_format() {
	static __format = undefined;
	
	if __format == undefined {
		vertex_format_begin();
		
		vertex_format_add_position_3d();
		vertex_format_add_texcoord();
		
		__format := vertex_format_end();
	}
	
	return __format;
}

#endregion
