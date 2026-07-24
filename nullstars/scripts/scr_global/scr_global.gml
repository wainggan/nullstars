 /*
global config.
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

function ns_config() {
	static __config := {
		game_loader_radius_file: 1024,
		game_loader_radius_parse: 512,
		game_loader_radius_load: 256,
		game_loader_budget_time: 2, // ms
		game_loader_budget_count: 10,
	};
	
	return __config;
}

// gml_release_mode(RELEASE);

