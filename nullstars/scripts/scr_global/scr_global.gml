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
		game_loader_radius_file: 1024,
		game_loader_radius_parse: 512,
		game_loader_radius_load: 256,
		game_loader_autotile_count: 20,
		game_loader_budget_time: 2, // ms
		game_loader_budget_count: 20,
	};
	
	return __config;
}

// gml_release_mode(RELEASE);

