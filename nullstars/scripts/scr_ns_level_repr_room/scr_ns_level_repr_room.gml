enum ns_level_RoomTarget {
	Unload,
	File,
	Parse,
	Load,
}

function ns_level_Budget() constructor {
	static tick := function () {};
	
	static okay := function () {
		return true;
	};
}

/**
@arg {struct.ns_level_World} _world
@arg {string} _id
@arg {real} _x in tiles
@arg {real} _y in tiles
@arg {real} _width in tiles
@arg {real} _height in tiles
*/
function ns_level_Room(_world, _id, _x, _y, _width, _height) constructor {
	LOG(Log.Hide, $"ns_level_Room(): initializing (@ {_id}; {_x} {_y} {_width} {_height})");
	
	world := _world;
	
	id := _id;
	// in tiles
	x := _x;
	y := _y;
	width := _width;
	height := _height;
	
	// used for collision testing
	object := instance_create_layer(_x * TILE_SIZE, _y * TILE_SIZE, "Instances", obj_room);
	with object {
		parent = other;
		image_xscale = _width * TILE_SIZE;
		image_yscale = _height * TILE_SIZE;
	}
	
	// entities owned by the room.
	entities := [];
	
	resources := {};
	for (var i = 0, _len := array_length(ns_level_component().list); i < _len; i++) {
		ns_level_component().list[i].init(self);
	}
	
	resource_buffer = undefined;
	
	resource_buffer_map = undefined;
	
	resource_entity_data = undefined;
	
	resource_state_autotile_vb = undefined;
	resource_state_autotile_iter = 0;
	resource_state_autotile_width = 0;
	resource_state_autotile_uv_left = 0;
	resource_state_autotile_uv_top = 0;
	resource_state_autotile_tex_width = 0;
	resource_state_autotile_tex_height = 0;
	resource_state_autotile_rules = undefined;
	
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
	
	target = ns_level_RoomTarget.Unload;
	target_frame = 0;
	
	/**
	@arg {Array<struct.RoomComponent>} _target
	@arg {struct.RoomBudget} _budget
	@return {enum.ns_level_RoomComponentStatus}
	*/
	static tick_components_list := function (_target, _budget) {
		for (var i = 0, _len := array_length(ns_level_component().list); i < _len; i++) {
			var _component := ns_level_component().list[i];
			
			if _component.state_get(self) == ns_level_RoomComponentState.Working {
				var _status := _component.tick(true, self, _budget);
				
				if !_budget.okay() {
					return ns_level_RoomComponentStatus.Waiting;
				}
				
				if _status != ns_level_RoomComponentStatus.Complete {
					return _status;
				}
			}
		}
		
		var _flagged = int64(0);
		
		for (var i = 0, _len := array_length(_target); i < _len; i++) {
			var _component := _target[i];
			
			var _found_index := array_get_index(ns_level_component().list, _component);
			ASSERT_NE_DEBUG(_found_index, -1, "oops");
			
			_flagged |= int64(1) << int64(_found_index);
			
			var _status := _component.tick(true, self, _budget);
			
			if !_budget.okay() {
				return ns_level_RoomComponentStatus.Waiting;
			}
			
			if _status != ns_level_RoomComponentStatus.Complete {
				return _status;
			}
		}
		
		for (var i = 0, _len := array_length(ns_level_component().list); i < _len; i++) {
			var _flag := (_flagged & int64(1)) == int64(0);
			_flagged = _flagged >> int64(1);
			
			if _flag {
				var _component := ns_level_component().list[i];
				
				var _status := _component.tick(false, self, _budget);
				
				if !_budget.okay() {
					return ns_level_RoomComponentStatus.Waiting;
				}
				
				if _status != ns_level_RoomComponentStatus.Complete {
					return _status;
				}
			}
		}
		
		return ns_level_RoomComponentStatus.Complete;
	};
	
	/**
	@arg {enum.ns_level_RoomTarget} _target
	@arg {struct.RoomBudget} _budget
	@return {enum.ns_level_RoomComponentStatus}
	*/
	static tick_components := function (_target, _budget) {
		var _list;
		
		if _target == ns_level_RoomTarget.Unload {
			_list := ns_level_component().phase_unload;
		}
		else if _target == ns_level_RoomTarget.File {
			_list := ns_level_component().phase_file;
		}
		else if _target == ns_level_RoomTarget.Parse {
			_list := ns_level_component().phase_parse;
		}
		else if _target == ns_level_RoomTarget.Load {
			_list := ns_level_component().phase_load;
		}
		else {
			ASSERT(false);
		}
		
		
		return self.tick_components_list(_list, _budget);
	};
	
	static tick_entities := function () {
		// update entities.
		
		for (var i = 0, _len := array_length(entities); i < _len; i++) {
			var _entity := entities[i];
			
			_entity.fn_tick();
		}
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
		
		array_resize(entities, 0);
	};
	
	static destroy := function () {
		instance_destroy(object);
	};
}
