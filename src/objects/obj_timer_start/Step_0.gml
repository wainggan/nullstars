
var _checkable = false;
if instance_exists(obj_player) {
	if dir == "right" || dir == "left" {
		if obj_player.bbox_bottom > bbox_top 
		&& obj_player.bbox_top < bbox_bottom
			_checkable = true;
	}
	if dir == "up" || dir == "down" {
		if obj_player.bbox_right > bbox_left
		&& obj_player.bbox_left < bbox_right
			_checkable = true;
	}
}

var _check = false;
if instance_exists(obj_player) {
	if dir == "left" {
		_check = bbox_right >= obj_player.bbox_right;
	}
	if dir == "right" {
		_check = bbox_left <= obj_player.bbox_left;
	}
	if dir == "down" {
		_check = bbox_top <= obj_player.bbox_top;
	}
	if dir == "up" {
		_check = bbox_bottom >= obj_player.bbox_bottom;
	}
}

var _start = !last_check && _check && _checkable && last_alive;
var _end = last_check && !_check && _checkable && last_alive;

last_check = _check;
last_able = _checkable;
last_alive = instance_exists(obj_player);

if !game_timer_running() && _start {
	game_timer_start(time * 60, self);
	
	game_set_pause(4)
	game_camera_set_shake(3, 0.5)
	
	instance_create_layer(x, y, layer, obj_effects_rectpop, {
		width: sprite_width,
		height: sprite_height,
		pad: 16,
		spd: 0.04
	});
	game_render_wave(x + sprite_width / 2, y + sprite_height / 2, 512, 60, 0.2, spr_wave_ripple);
	game_render_particle_ambient(x + sprite_width / 2, y + sprite_height / 2, ps_timer_start);
}

if _end {
	var _cond = false;
	
	if game_timer_running() && global.game.state.timer_target == self {
		game_timer_stop()
		_cond = true;
	}
	
	if _cond {
		game_set_pause(4);
		instance_create_layer(x, y, layer, obj_effects_rectpop, {
			width: sprite_width,
			height: sprite_height,
			pad: 16,
			spd: 0.04
		});
	}
	
}

var _letsgoo = global.game.state.timer_target == self;


with level_get_instance(ref) {
	
	if !global.game.gate.data(other.name).complete && game_level_get_safe(x, y) {
		if game_timer_running() && _letsgoo {
			if instance_exists(other.pet) {
				instance_destroy(other.pet);
			}
		} else {
			if !instance_exists(other.pet) {
				other.pet = instance_create_layer(x, y, layer, obj_Solid, {
					image_xscale: sprite_width,
					image_yscale: sprite_height
				});
				other.pet.outside = exists_outside_empty;
			}
		}
	} else {
		if instance_exists(other.pet) {
			instance_destroy(other.pet);
		}
	}
	
	if !_letsgoo {
		break;
	}
	
	var _touch = place_meeting(x, y, obj_player);
	var _cond = _touch && !lastTouch;
	lastTouch = _touch;

	if _cond {
		var _pop = false;
	
		if game_timer_running() {
			global.game.gate.data(other.name).complete = true;
			global.game.gate.data(other.name).time = game_timer_get();
			
			game_file_save();
			
			game_timer_stop();
			other.anim_pop = true;
			
			game_render_wave(x + sprite_width / 2, y + sprite_height / 2, 960, 120, 0.5, spr_wave_ripple);
		
			_pop = true;
		}

		if global.onoff == false {
			global.onoff = true;
			_pop = true;
		}
	
		if _pop {
			game_set_pause(4);
	
			instance_create_layer(x, y, layer, obj_effects_rectpop, {
				width: sprite_width,
				height: sprite_height,
				pad: 16,
				spd: 0.04
			});
		}
	}
}

anim_running = approach(anim_running, _letsgoo, 0.08);
var _last_is_complete = anim_is_complete;
anim_is_complete = global.game.gate.data(other.name).complete;
anim_complete = approach(anim_complete, +anim_is_complete, 0.06);
anim_wall = approach(anim_wall, anim_is_complete || _letsgoo ? 1 : 0, 0.1);

if anim_pop {
	anim_running = 0;
}

