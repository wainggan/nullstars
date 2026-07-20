
/**
the main engine of nullstars.

this object provides the main gameplay loop and orchestration for all modules that need it,
accessible via the singleton `global.root`. game code should use functions that abstract over
directly accessing this.

@arg {struct.AsyncHook} _async
*/
function ns_Root(_async) constructor {
	LOG(Log.Note, "ns_Root(): initializing");
	
	// ns_Root() is a singleton.
	ASSERT_EQ(global.__ns_root, undefined, "created ns_Root() twice.");
	
	global.__ns_root = self;
	
	async := _async;
	
	// parse the package.
	package = new Package(undefined);
	
	// parse world data.
	world = new ns_level_World(package);
	
	camera := new Camera();
	
	render := new Render();
	
	static tick := function () {
		camera.tick();
		
		var _kh = keyboard_check(vk_right) - keyboard_check(vk_left);
		var _kv = keyboard_check(vk_down) - keyboard_check(vk_up);
		
		camera.x += _kh * 4;
		camera.y += _kv * 4;
		
		world.tick();
		
		if keyboard_check_pressed(ord("B")) {
			world.entity_global_add(instance_create_layer(-64, 64, "Instances", obj_game_Nova));
		}
		if keyboard_check_pressed(ord("N")) {
			with instance_create_layer(-64, 64, "Instances", obj_game_Solid) {
				image_xscale = 16;
				image_yscale = 16;
				image_blend = #ff00ff;
				other.world.entity_global_add(self);
			}
		}
	};
	
	static draw := function () {
		render.draw(self);
	};
}

global.__ns_root = undefined;

function ns_root() {
	ASSERT_NE(global.__ns_root, undefined);
	return global.__ns_root;
}

function AsyncHook() constructor {
	__registered_file := [];
	
	/**
	@arg {struct} _item
	*/
	static register_file := function (_item, _load_id) {
		ASSERT(is_struct(_item));
		ASSERT(is_method(variable_struct_get(_item, "hook")));
		
		array_push(
			__registered_file,
			{
				item: _item,
				load_id: _load_id,
			}
		);
	};
	
	/**
	@arg {id.DsMap} _dsmap
	*/
	static hook_file := function (_dsmap) {
		for (var i = 0, _len := array_length(__registered_file); i < _len; i++) {
			var _item := __registered_file[i];
			if ds_map_find_value(_dsmap, "id") == _item.load_id {
				if !ds_map_find_value(_dsmap, "status") {
					LOG(Log.Error, $"AsyncHook(): file '{_item.load_id}' couldn't be loaded. does it even exist?");
					LOG(Log.Error, $"AsyncHook(): this is an unrecoverable error. fuck you. crashing now");
					ASSERT(false, $"see logs asshole");
				}
				
				_item.item.hook();
				
				array_delete(__registered_file, i--, 1);
				
				return;
			}
		}
		
		LOG(Log.Warn, $"AsyncHook(): passed by async event without hook firing");
	};
}

