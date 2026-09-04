/*
global config.

macros are for situations where
1. gamemaker's compile time collapsing makes the nature of the config's usage faster. (see: RELEASE)
2. the config is probably a bad idea to change. (see: TILE_SIZE)

ns_config() is for situations where
1. it might be useful to change the value at runtime through the debugger or in-game settings.
*/

// whether the game is in 'release mode'. when true, various
// safety and integrity checks will be disabled to help with performance.
#macro RELEASE false

#macro DEBUG_LOAD_TRACK_OPS true
#macro DEBUG_LOAD_EMIT_COMPONENT_TICK_LOGS true
#macro DEBUG_LOAD_EMIT_COMPONENT_COMPLETE_LOGS true

// it'd probably be a bad idea to let these change
#macro WINDOW_WIDTH 960
#macro WINDOW_HEIGHT 540

#macro TILE_SIZE 16

// todo: it might be a better idea to move this to ns_Root(), for an
// easier time modifying it when resolving settings.
function ns_config() {
	static __config := {
		gen_terminal_vel: 5,
		
		nova_move_speed: 3,//2,
		nova_move_accel: 0.5,
		nova_move_accel_fast: 0.8,
		nova_move_slowdown: 0.08,
		nova_move_slowdown_air: 0.04,
		nova_gravity: 0.45,
		nova_gravity_hold: 0.3,//0.26,
		nova_gravity_peak: 0.1,
		nova_gravity_peak_thresh: 0.36,
		nova_gravity_term: 0.12,
		nova_jump_vel: 4.8,
		nova_jump_time: 6,//3,
		nova_jump_damp: 0.6,
		nova_jump_move_boost: 0.4,
		nova_terminal_vel_hold: 1,
		nova_terminal_vel_fast: 7,
		nova_ledge_stick: 4,
		nova_buffer_jump: 10,
		nova_buffer_ground: 4,
		
		loader_radius_file: 1024,
		loader_radius_parse: 512,
		loader_radius_load: 256,
		
		loader_autotile_iter_count: 20,
		loader_collision_velocity_iter_count: 20,
		
		loader_budget_time: 2, // ms
		loader_budget_count: 20,
	};
	
	return __config;
}

// gml_release_mode(RELEASE);

