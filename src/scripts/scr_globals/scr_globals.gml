
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

#macro GAME_BUBBLE_PARITY 8

#macro GAME_RENDER_LIGHT_SIZE 2048
#macro GAME_RENDER_LIGHT_KERNEL 256

#macro GAME_LOAD_RADIUS_FILE 512
#macro GAME_LOAD_RADIUS_ENTITY 128
// how long it takes to unload the entities of a level
#macro GAME_LOAD_TIME_FILE 180
// how long it takes to unload level data
#macro GAME_LOAD_TIME_PREP 240

