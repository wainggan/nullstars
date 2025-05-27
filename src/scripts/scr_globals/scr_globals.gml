
#macro RELEASE false
#macro Release:RELEASE true

gml_release_mode(RELEASE);

global.defs = {
	// global terminal velocity
	terminal_vel: 5,
	// speed of lifts when returning back to normal positions
	lift_spd_return: 2,
	// how long lifts get stunned after reaching their final position in frames
	// note: this effects how long momentum retention is as well
	lift_stun_time: 10,
}

global.config = {
	_demonstrate: false,
	graphics_lights: true,
	graphics_lights_shadow: true,
	graphics_lights_rimblur: true,
	graphics_atmosphere_particles: true,
	graphics_atmosphere_overlay: true,
	graphics_reflectables: true,
	graphics_post_outline: true,
	graphics_post_grading: true,
	graphics_up_bubble_wobble: true,
	graphics_up_bubble_outline: true,
	graphics_up_bubble_spike: true,
	slow: false,
}


#macro WIDTH 960
#macro HEIGHT 540

#macro TILESIZE 16

#macro ENABLE_LOG true

#macro GAME_PARITY_BUBBLE 8
#macro GAME_PARITY_ENTITY 6

#macro GAME_RENDER_LIGHT_SIZE 2048
#macro GAME_RENDER_LIGHT_KERNEL 256

// amount of time loader may spend working during a frame in ms
#macro GAME_LOAD_BUDGET_TIME 1
// amount of jobs loader may complete in one frame
#macro GAME_LOAD_BUDGET_COUNT 4

#macro GAME_LOAD_RADIUS_FILE 512
#macro GAME_LOAD_RADIUS_ENTITY 128
// how long it takes to unload the entities of a level
#macro GAME_LOAD_TIME_FILE 180
// how long it takes to unload level data
#macro GAME_LOAD_TIME_PREP 240

// if the distance between player and checkpoint is larger than this, respawning will cause a screenfade
#macro GAME_RESPAWN_FADE_THRESHOLD 3072

// slows down level loading
#macro DEBUG_LOAD_SLOW_ENABLE false 
#macro DEBUG_LOAD_SLOW_FILE 30
#macro DEBUG_LOAD_SLOW_PARSE 50

