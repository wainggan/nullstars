
if instance_number(obj_player) > 1 {
	instance_destroy();
	exit;
}

event_inherited();

defs = {
	move_speed: 2,
	move_accel: 0.5,
	move_accel_fast: 0.8,
	move_slowdown: 0.08,
	move_slowdown_air: 0.04,
	
	gravity: 0.45,
	gravity_hold: 0.26,
	gravity_peak: 0.1,
	gravity_peak_thresh: 0.36,
	gravity_term: 0.12,
	
	boost_limit_x: 9,
	boost_limit_y: 4,
	
	jump_vel: -4.8,
	jump_time: 3,
	jump_damp: 0.6,
	jump_move_boost: 0.4,
	
	walljump_grace: 5,
	
	dashjump_time: 3,
	dashjump_fast_vel: -3.2,
	dashjump_fast_key_force: 6,
	dashjump_high_time: 8,
	
	terminal_vel: global.defs.terminal_vel,
	terminal_vel_fast: 7,
	
	wall_distance: 4,
	
	dash_total: 1,
	
	buffer: 10,
	grace: 5,
	
	anim_dive_time: 20,
	anim_jab_time: 20,
	anim_longjump_time: 30,
};


scale_x = 0;
scale_y = 0;

x_last = x;
y_last = y;

x_delta = 0;
y_delta = 0;

dir = 1;

light = instance_create_layer(x, y, "Lights", obj_light, {
	color: #ffffff,
	size: 60,
	intensity: 0.5,
});

buffer_jump = 0;
buffer_dash = 0;

nat_crouch = function(_value = undefined) {
	if _value != undefined {
		if _value {
			mask_index = spr_hitbox_player_crouch;
		} else {
			mask_index = spr_hitbox_player;
		}
	}
	return mask_index == spr_hitbox_player_crouch;
};
nat_crouch(false);

get_can_uncrouch = function() {
	if !nat_crouch() {
		return true;
	}
	var _pre = mask_index;
	mask_index = spr_hitbox_player;
	
	var _collide = actor_collision(x, y);
	var _inst = instance_place(x, y, obj_ss_down);
	if _inst != noone {
		_collide = true;
	}
	
	mask_index = _pre;
	return !_collide;
};

onground = false;
onground_last = false;

grace = 0;
grace_y = 0;

vel_keygrace = 0;
vel_grace = 0;
vel_grace_timer = 0;

hold_jump_key_timer = 0;
hold_jump_vel = 0;
hold_jump_vel_timer = 0;

key_force = 0;
key_force_timer = 0;

walljump_grace = 0;
walljump_grace_dir = 0;
walljump_solid = noone;
walljump_solid_x = 0;
walljump_solid_y = 0;

// direction of dash (-1 | 0 | 1)
dash_dir_x = 0;
dash_dir_y = 0;
// speed of dash
dash_dir_x_vel = 0;
dash_dir_y_vel = 0;
// speed before dash
dash_pre_x_vel = 0;
dash_pre_y_vel = 0;
// frames left to dash
dash_timer = 0;
// how long has dash been happening?
dash_frame = 0;
dash_grace = 0;
dash_grace_kick = 0;
dash_recover = 0;
// player should long jump on the next frame
dash_jump = false;
// increases when dashing on the ground, lowers when not dashing, reset after jumping
// reduces the effectiveness of reverse dashing
dash_stale = 0;

swim_dir = 0;
swim_spd = 0;
swim_pre_x_vel = 0;
swim_pre_y_vel = 0;
swim_frame = 0;


dash_left = defs.dash_total;

cam_ground_x = x;
cam_ground_y = y;

respawn_timer = 0;
respawn_dyn = 0;


#region animation

anim = new AnimController();
anim.add("idle", new AnimLevel([PlayerFrame.stand]));
anim.add("walk", new AnimLevel([
		PlayerFrame.walk_1a, PlayerFrame.walk_2a,
		PlayerFrame.walk_1b, PlayerFrame.walk_2b,
	], 12));
anim.add("jump", new AnimLevel([PlayerFrame.jump]));
anim.add("fall", new AnimLevel([PlayerFrame.fall]));
anim.add("dive", new AnimLevel([PlayerFrame.dive]));
anim.add("jab", new AnimLevel([PlayerFrame.dash]));
anim.add("longjump", new AnimLevel([PlayerFrame.long]));
anim.add("swim", new AnimLevel([PlayerFrame.swim_idle_1, PlayerFrame.swim_idle_2], 1 / 60))
anim.add("swimming", new AnimLevel([PlayerFrame.swim_1, PlayerFrame.swim_2], 1 / 60))
anim.add("swimbullet", new AnimLevel([PlayerFrame.swim_bullet], 1))
anim.add("ledge", new AnimLevel([PlayerFrame.ledge]))
anim.add("crouch", new AnimLevel([PlayerFrame.crouch]))
anim.add("flip", new AnimLevel([PlayerFrame.flip_1, PlayerFrame.flip_2], 1 / 14, 0))
anim.add("run", new AnimLevel([
		PlayerFrame.run_1, PlayerFrame.run_1,
		PlayerFrame.run_2, PlayerFrame.run_2, PlayerFrame.run_2,
		PlayerFrame.run_3, PlayerFrame.run_3
	], 1/12))
.add("runjump", new AnimLevel([PlayerFrame.run_jump]))
.add("runfall", new AnimLevel([PlayerFrame.run_fall]))

.meta_default({
	x: -2, y: -16,
	front: false,
})
.meta_items([PlayerFrame.walk_1a, PlayerFrame.walk_1b], {
	y: -15,
})
.meta_items([PlayerFrame.jump, PlayerFrame.fall], {
	y: -17,
})
.meta_items([PlayerFrame.dive], {
	x: -4, y: -21,
	front: true,
})
.meta_items([PlayerFrame.long], {
	x: -8, y: -16,
})
.meta_items([PlayerFrame.dash], {
	x: 3, y: -11,
})
.meta_items([PlayerFrame.swim_idle_1], {
	x: -4, y: -17,
})
.meta_items([PlayerFrame.swim_idle_2], {
	x: -5, y: -15,
})
.meta_items([PlayerFrame.swim_1], {
	x: -4, y: -16,
})
.meta_items([PlayerFrame.swim_2], {
	x: -4, y: -17,
})
.meta_items([PlayerFrame.swim_bullet], {
	x: 0, y: 0,
})
.meta_items([PlayerFrame.ledge], {
	x: -4, y: -17,
})
.meta_items([PlayerFrame.crouch], {
	x: -5, y: -6,
})
.meta_items([PlayerFrame.flip_1, PlayerFrame.flip_2], {
	x: -2, y: -15,
})
.meta_items([PlayerFrame.run_2], {
	x: -5, y: -13,
})
.meta_items([PlayerFrame.run_3], {
	x: -8, y: -16,
})
.meta_items([PlayerFrame.run_1], {
	x: -8, y: -16,
})
.meta_items([PlayerFrame.run_fall], {
	x: -3, y: -15,
});

depth -= 10;

anim_dive_timer = 0;
anim_jab_timer = 0;
anim_longjump_timer = 0;
anim_flip_timer = 0;
anim_runjump_timer = 0;

action_anim_onground = function() {
	anim_longjump_timer = 0;
	anim_flip_timer = 0;
	anim_runjump_timer = 0;
};
action_anim_ledge = function() {
	anim_longjump_timer = 0;
	anim_flip_timer = 0;
};
action_anim_jump = function() {
	anim_dive_timer = 0;
	anim_jab_timer = 0;
	anim_flip_timer = 0;
	anim_runjump_timer = 0;
};
action_anim_dashjump = function() {
	anim_longjump_timer = defs.anim_longjump_time;
};
action_anim_dashjump_wall = function() {
	anim_flip_timer = 30;
};
action_anim_dash = function() {
	anim_runjump_timer = 0;
	if dash_dir_y > 0 {
		anim_dive_timer = defs.anim_dive_time;
	} else {
		anim_jab_timer = defs.anim_jab_time;
	}
};

#endregion

tail = new PlayerTail(x, y);


#region methods

get_check_water = function(_x, _y) {
	return place_meeting(_x, _y, obj_water) &&
		place_meeting(_x, _y - 16, obj_water) &&
		place_meeting(_x, _y + 6, obj_water);
}

get_check_wall = function(_dir, _dist = defs.wall_distance) {
	return actor_collision(x + _dir * _dist, y);
};

get_lift_x = function() {
	var _out = actor_lift_get_x();
	return clamp(_out, -defs.boost_limit_x, defs.boost_limit_x);
};
get_lift_y = function() {
	var _out = actor_lift_get_y();
	return clamp(_out, -defs.boost_limit_y, 0);
};

get_check_death = function(_x, _y) {
	
	var _inst = instance_place(_x, _y, obj_spike);
	with _inst {
		if object_index == obj_spike_up && other.y_vel >= 0 return true;
		if object_index == obj_spike_down && other.y_vel <= 0 return true;
		if object_index == obj_spike_left && other.x_vel >= 0 return true;
		if object_index == obj_spike_right && other.x_vel <= 0 return true;
		return true;
	}
	
	static __size = 5;
	
	var _left = (bbox_left - x) + _x + 1;
	var _top = (bbox_top - y) + _y + 1;
	var _right = (bbox_right - x) + _x - 1;
	var _bottom = (bbox_bottom - y) + _y - 1;
	
	for (var i_level = 0; i_level < array_length(global.game.level.loaded); i_level++) {
		
		var _lvl = global.game.level.loaded[i_level].data;
		var _tm = _lvl.tiles_spike;
		var _l_x = _lvl.x;
		var _l_y = _lvl.y;
		var _width = tilemap_get_width(_tm);
		var _height = tilemap_get_height(_tm);
		
		for (var _yy = max(0, (_top - _l_y) div TILESIZE - 1),
			_yy_l = min(_height, (_bottom - _l_y) div TILESIZE + 1);
			_yy < _yy_l; _yy++;
		) {
			for (var _xx = max(0, (_left - _l_x) div TILESIZE - 1),
				_xx_l = min(_width, (_right - _l_x) div TILESIZE + 1);
				_xx < _xx_l; _xx++;
			) {
				
				var _tile = tilemap_get(_tm, _xx, _yy);
				
				var _xp = _xx * TILESIZE + _l_x;
				var _yp = _yy * TILESIZE + _l_y;
				
				if _tile == 0 {
					continue;
				}
				
				switch _tile {
					case 1: {
						// 6 indents!! yippee
						if x_vel > 0 {
							break;
						}
						if !rectangle_in_rectangle(
							_left, _top, _right, _bottom,
							_xp, _yp, _xp + __size, _yp + 16
						) {
							break;
						}
						return true;
					}
					case 2: {
						if y_vel < 0 {
							break;
						}
						if !rectangle_in_rectangle(
							_left, _top, _right, _bottom,
							_xp, _yp + 16 - __size, _xp + 16, _yp + 16
						) {
							break;
						}
						return true;
					}
					case 3: {
						if x_vel < 0 {
							break;
						}
						if !rectangle_in_rectangle(
							_left, _top, _right, _bottom,
							_xp + 16 - __size, _yp, _xp + 16, _yp + 16
						) {
							break;
						}
						return true;
					}
					case 4: {
						if y_vel > 0 {
							break;
						}
						if !rectangle_in_rectangle(
							_left, _top, _right, _bottom,
							_xp, _yp, _xp + 16, _yp + __size
						) {
							break;
						}
						return true;
					}
				}
				
			}
		}
		
	}
	
	return false;
	
};

#endregion

#region methods: jumps

action_jump_shared = function() {
	
	buffer_jump = 0;
	grace = 0;
	
	dash_grace = 0;
	dash_grace_kick = 0;
	dash_stale = 0;
	
	hold_jump_key_timer = 0;
	hold_jump_vel = defs.terminal_vel;
	hold_jump_vel_timer = 0;
	
	action_anim_jump();
	
};

action_jump = function() {
	
	var _kh = INPUT.check("right") - INPUT.check("left");
	var _kv = INPUT.check("down") - INPUT.check("up");
	
	if grace > 0 {
		actor_move_y(grace_y - y);
	}
	
	action_jump_shared();
	
	y_vel = min(y_vel, defs.jump_vel);
	if !INPUT.check("jump") {
		y_vel *= defs.jump_damp;
	}
	
	if _kh != 0 && abs(x_vel) < defs.move_speed {
		x_vel = defs.move_speed * _kh;
	}
	x_vel += defs.jump_move_boost * _kh;
	
	hold_jump_key_timer = 0;
	hold_jump_vel = y_vel;
	hold_jump_vel_timer = defs.jump_time;
	
	x_vel += get_lift_x();
	y_vel += get_lift_y();
	
	dash_left = defs.dash_total;
	
	scale_x = 0.7;
	scale_y = 1.3;
	
	if abs(x_vel) > defs.move_speed + 2 {
		anim_runjump_timer = 120;
	}
	
	game_sound_play(sfx_pop_0);
	
};

action_walljump = function() {
	
	walljump_solid = instance_place(x + dir, y, obj_Solid);
	if walljump_solid != noone {
		walljump_solid_x = walljump_solid.x;
		walljump_solid_y = walljump_solid.y;
	}
	
	if actor_lift_get_x() == 0 && actor_lift_get_y() == 0 {
		var _inst = instance_place(x + dir * defs.wall_distance, y, obj_Solid);
		if _inst != noone {
			actor_lift_set(_inst.lift_x, _inst.lift_y);
		}
	}
	
	action_jump();
	
	anim_runjump_timer = 0;
	
	hold_jump_key_timer = 5;
	
	walljump_grace = defs.walljump_grace;
	walljump_grace_dir = dir;
	
};

action_dashjump = function(_key_dir) {
	
	if grace > 0 {
		actor_move_y(grace_y - y);
	}
	
	action_jump_shared();
	
	action_anim_dashjump();
	
	if dash_dir_y == 0 {
		if _key_dir == dash_dir_x {
			// normal long jump
			
			x_vel = 5 * _key_dir;
			
			y_vel = defs.jump_vel;
			hold_jump_vel_timer = defs.dashjump_time;
		} else {
			// high jump
			
			x_vel = abs(x_vel) * 0.8 * _key_dir;
			
			y_vel = defs.jump_vel;
			hold_jump_vel_timer = defs.dashjump_high_time;
		}
	} else {
		// fast long jump
		
		var _key_dir_adjust = _key_dir == 0 ? dir : _key_dir;
		
		x_vel = max(abs(x_vel) * 1, 8) * _key_dir_adjust;
		
		key_force = _key_dir_adjust;
		key_force_timer = defs.dashjump_fast_key_force;
		
		y_vel = defs.dashjump_fast_vel;
		hold_jump_vel_timer = defs.dashjump_time;
	}
	if !INPUT.check("jump") {
		y_vel *= defs.jump_damp;
	}
	
	hold_jump_key_timer = 0;
	hold_jump_vel = y_vel;
	
	if get_can_uncrouch() {
		nat_crouch(false);
	}
	
	x_vel += get_lift_x();
	y_vel += get_lift_y();
	
	scale_x = 0.8;
	scale_y = 1.2;
	
	game_sound_play(sfx_pop_2);
	
};

action_dashjump_wall = function(_key_dir, _wall_dir) {
	
	action_jump_shared();
	
	action_anim_dashjump_wall();
	
	if dash_recover <= 0 {
		dash_left = defs.dash_total;
	}
	
	y_vel = defs.jump_vel - 0.5;
	x_vel = -_wall_dir * 3;
	
	key_force_timer = 7;
	
	key_force = -_wall_dir;
	dir = -_wall_dir;
	
	hold_jump_key_timer = 5;
	hold_jump_vel = y_vel;
	hold_jump_vel_timer = 10;
	
	vel_grace = 0;
	vel_grace_timer = 0;
	
	x_vel += get_lift_x();
	y_vel += get_lift_y();
	
	scale_x = 0.6;
	scale_y = 1.4;
	
	game_sound_play(sfx_pop_2);
	
};

impl_jump_bounce = function(_dir, _from_x, _from_y) {
	
	actor_move_y(_from_y - y);
	
	action_jump_shared();
	
	state.change(state_free);

	y_vel = defs.jump_vel - 2;
	
	hold_jump_key_timer = 48;
	hold_jump_vel = y_vel;
	hold_jump_vel_timer = 7;
	
	dash_left = defs.dash_total;
	
	scale_x = 0.6;
	scale_y = 1.4;
	
}

event.add("bounce", impl_jump_bounce);

#endregion


state = new State();

state_stuck = state.add();
state_stuck.set("step", function() {
	if game_paused() {
		return;
	}
	x_vel = approach(x_vel, 0, 0.5);
	y_vel = approach(y_vel, defs.terminal_vel, defs.gravity);
	
	actor_move_x(x_vel);
	actor_move_y(y_vel);
	
	if actor_collision(x, y + 1) {
		state.change(state_free);
	}
});

state_base = state.add();
state_base.set("step", function () {
	
	var _kh = INPUT.check("right") - INPUT.check("left");
	var _kv = INPUT.check("down") - INPUT.check("up");
	
	buffer_jump -= 1;
	buffer_dash -= 1;
	if INPUT.check_pressed("jump") {
		buffer_jump = defs.buffer + 1;
	}
	if INPUT.check_pressed("dash") {
		buffer_dash = defs.buffer + 1;
	}
	
	if game_paused() {
		return;
	}
	
	x_delta = x - x_last;
	y_delta = y - y_last;
	
	x_last = x;
	y_last = y;
	
	scale_x = lerp(scale_x, 1, 0.2);
	scale_y = lerp(scale_y, 1, 0.2);
	
	if state.is(state_free) || state.is(state_dash) {
	 	if walljump_solid != noone {
			if walljump_solid.x != walljump_solid_x || walljump_solid.y != walljump_solid_y {
				actor_move_x(walljump_solid.x - walljump_solid_x);
				actor_move_y(walljump_solid.y - walljump_solid_y);
				walljump_solid_x = walljump_solid.x;
				walljump_solid_y = walljump_solid.y;
			}
			var _solid = instance_place(x + dir, y, obj_Solid);
			if _solid != walljump_solid {
				walljump_solid = noone;
			}
		}
	} else {
		walljump_solid = noone;
	}
	
	if y_vel >= 0 {
		onground = actor_collision(x, y + 1);
	} else {
		onground = false;
	}
	
	grace -= 1;
	dash_recover -= 1;
	if onground {
		grace = defs.grace;
		grace_y = y;
		
		action_anim_onground();
	}
	
	if (grace > 0 && dash_recover <= 0) || (state.is(state_ledge)) {
		dash_left = defs.dash_total;
	}
	
	dash_stale = approach(dash_stale, 0, 3 / 60);
	
	state.child();
	
	static __collide_x = function() {
		var _amount = 0;
		if state.is(state_dash) {
			_amount = 12;
		} else {
			_amount = 0;
		}
		
		for (var i = 0; i < _amount * 2 + 1; i++) {
			var _d = (i % 2 == 0 ? 1 : -1) * floor((i + 2) / 2);
			if !actor_collision(x + sign(x_vel), y + _d) {
				actor_move_y(_d);
				// avoid getting stuck
				// it's probably fine...
				actor_move_x(sign(x_vel));
				return;
			}
		}
		
		if vel_grace_timer <= 0 || abs(x_vel) > abs(vel_grace) { // bad idea
			vel_grace_timer = 14;
			vel_grace = x_vel;
		}
		if state.is(state_swim_bullet) {
			swim_dir = point_direction(0, 0, -x_vel, y_vel);
		} else {
			x_vel = 0;
		}
	};
	actor_move_x(x_vel, __collide_x);
	
	static __collide_y = function() {
		var _amount = 0;
		if y_vel < 0 || (dash_grace > 0 && dash_dir_y == 1 && dash_dir_x == 0) {
			_amount = 8;
		} else {
			_amount = 2;
		}
		
		for (var i = 0; i < _amount * 2 + 1; i++) {
			var _d = (i % 2 == 0 ? 1 : -1) * floor((i + 2) / 2);
			if !actor_collision(x + _d, y + sign(y_vel)) {
				actor_move_x(_d);
				actor_move_y(sign(y_vel));
				return;
			}
		}
		
		if y_vel > 0 {
			if state.is(state_free) && y_vel > 1 {
				scale_x = 1.2;
				scale_y = 0.8;
				game_sound_play(sfx_pop_1);
			}
		}
		if state.is(state_swim_bullet) {
			swim_dir = point_direction(0, 0, x_vel, -y_vel);
		} else {
			y_vel = 0;
		}
	};
	actor_move_y(y_vel, __collide_y);
	
	// if still colliding, you're inside a wall...
	// escape!!
	if actor_collision(x, y) {
		var _out = false;
		for (var i = 0; i < 16 * 2; i++) {
			var _d = (i % 2 == 0 ? 1 : -1) * floor((i + 2) / 2);
			if !actor_collision(x + _d, y) {
				x += _d;
				_out = true;
				break;
			}
			if !actor_collision(x, y + _d) {
				y += _d;
				_out = true;
				break;
			}
		}
		if !_out {
			game_player_kill();
			return;
		}
	}
	
	var _inst = instance_place(x, y, obj_dash);
	if dash_left < defs.dash_total && _inst && _inst.state.is(_inst.state_active) {
		game_set_pause(4);
		dash_left = defs.dash_total;
		_inst.state.change(_inst.state_recover);
	}
	
	// this is horrible
	if state.is(state_free) {
		if y_vel > -1 {
			if get_check_wall(dir, 1) && INPUT.check("grab") {
				var _crouched = nat_crouch();
				if !_crouched || (_crouched && get_can_uncrouch()) {
					nat_crouch(false);
					state.change(state_ledge);
					return;
				}
			}
		}
	}
	
	if instance_exists(light) {
		light.x = x;
		light.y = y - (nat_crouch() ? 14 : 22);
	}
	
	if get_check_death(x, y) {
		game_player_kill();
	}
	
	actor_lift_update();
	
	onground_last = onground;
	dash_grace -= 1;
	dash_grace_kick -= 1;
	vel_grace_timer -= 1;
	
	if state.is(state_free) || state.is(state_swim) {
		if INPUT.check_pressed("menu") &&
			(place_meeting(x, y, obj_checkpoint) || place_meeting(x, y, obj_checkpoint_dyn)) &&
			!nat_crouch() &&
			!state.is(state_swim)
		{
			state.change(state_menu);
			return;
		} else if INPUT.check("menu") {
			respawn_timer += 1;
			if respawn_timer > 17 {
				game_player_kill();
			}
			
			if INPUT.check_pressed("menu") && (onground || state.is(state_swim)) {
				if respawn_dyn <= 0 {
					respawn_dyn = 17;
				} else {
					respawn_timer = 0;
					respawn_dyn = 0;
					game_checkpoint_set_dyn(x, y);
					
					game_set_pause(4);
					game_render_particle(x, y - 16, ps_player_death_1);
					
					game_render_wave(x, y - 16, 256, 60, 0.8, spr_wave_sphere);
				}
			}
		} else {
			respawn_timer = approach(respawn_timer, 0, 2);
			// aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
		}
	} else {
		respawn_timer = approach(respawn_timer, 0, 2);
	}
	respawn_dyn -= 1;
	
	if place_meeting(x, y, obj_flag_stop) {
		state.change(state_stuck);
		return;
	}
	
});

state_stuck = state_base.add()
.set("step", function(){
	x_vel = approach(x_vel, 0, 0.5);
	y_vel = approach(y_vel, defs.terminal_vel, defs.gravity);
	if actor_collision(x, y + 1) {
		state.change(state_free);
	}
});

state_free = state_base.add();
state_free.set("step", function () {
	
	var _kh = INPUT.check("right") - INPUT.check("left");
	var _kv = INPUT.check("down") - INPUT.check("up");
	
	var _k_move = _kh;
	key_force_timer -= 1;
	if key_force_timer > 0 {
		_k_move = key_force;
	}
	if onground && nat_crouch() {
		_k_move = 0;
	}
	
	if vel_grace_timer > 0 {
		if _kh != sign(vel_grace) {
			vel_grace_timer = 0;
		} else if !actor_collision(x + _kh, y) {
			x_vel = vel_grace;
			vel_grace_timer = 0;
		}
	}
	
	var _x_accel = 0;
	if abs(x_vel) > defs.move_speed && _k_move == sign(x_vel) {
		_x_accel = defs.move_slowdown;
		if !onground {
			vel_keygrace = 6;
			_x_accel = defs.move_slowdown_air;
		}
	} else {
		if abs(x_vel) > defs.move_speed && _k_move == -sign(x_vel) {
			_x_accel = defs.move_accel_fast;
		} else {
			_x_accel = defs.move_accel;
		}
		if nat_crouch() {
			_x_accel = 0.2;
		}
	}
	
	vel_keygrace -= 1;
	if vel_keygrace > 0 && _k_move != sign(x_vel) {
		if onground {
			_x_accel = defs.move_slowdown;
		} else {
			_x_accel = defs.move_slowdown_air;
		}
	}
	
	walljump_grace -= 1;
	if walljump_grace > 0 {
		if walljump_grace_dir == -dir {
			if dir != 0 && abs(x_vel) < defs.move_speed {
				x_vel = defs.move_speed * dir;
				x_vel += defs.jump_move_boost * dir;
			}
		}
	}
	
	x_vel = approach(x_vel, _k_move * defs.move_speed, _x_accel);
	
	if _kh != 0 {
		if dir != _kh && onground && nat_crouch() {
			scale_x = 0.8;
			scale_y = 1.2;
		}
		dir = _kh;
	}
	
	var _k_jump = INPUT.check("jump");
	if hold_jump_key_timer > 0 {
		_k_jump = true;
	}
	
	var _y_accel = 0;
	
	if _k_jump {
		if abs(y_vel) < defs.gravity_peak_thresh {
			_y_accel = defs.gravity_peak;
		} else {
			_y_accel = defs.gravity_hold;
		}
	} else {
		_y_accel = defs.gravity;
	}
	if y_vel >= defs.terminal_vel {
		_y_accel = defs.gravity_term;
	}
	
	if (INPUT.check_released("jump") && hold_jump_key_timer <= 0) && y_vel < 0 {
		y_vel *= defs.jump_damp;
		hold_jump_vel_timer = 0;
	}
	
	var _termvel = defs.terminal_vel;
	if _kv == 1 {
		_termvel = defs.terminal_vel_fast;
	}
	
	if INPUT.check("jump") {
		_termvel -= 1;
	}
	
	if hold_jump_key_timer > 0 {
		hold_jump_key_timer -= 1;
		if hold_jump_key_timer <= 0 && !INPUT.check("jump") {
			y_vel *= defs.jump_damp;
			hold_jump_vel_timer = 0;
		}
	}
	if hold_jump_vel_timer > 0 {
		hold_jump_vel_timer -= 1;
		if _k_jump {
			y_vel = min(y_vel, hold_jump_vel);
		}
	}
	if !_k_jump {
		hold_jump_vel_timer = 0;
	}
	
	if !onground {
		y_vel = approach(y_vel, _termvel, _y_accel);
	}
	
	if !onground && onground_last && y_vel >= 0 {
		x_vel += get_lift_x();
		y_vel += get_lift_y();
		if abs(x_vel) > defs.move_speed + 2 {
			anim_runjump_timer = 120;
		}
	}
	
	if nat_crouch() {
		if get_can_uncrouch() {
			if onground && !INPUT.check("down") {
				nat_crouch(false);
				scale_x = 0.8;
				scale_y = 1.2;
			}
			if !onground && y_vel >= 0 && !INPUT.check("down") {
				nat_crouch(false);
				scale_x = 0.8;
				scale_y = 1.2;
			}
		}
	} else {
		if onground && INPUT.check("down") {
			nat_crouch(true);
			scale_x = 1.2;
			scale_y = 0.8;
		}
	}
	
	if buffer_dash > 0 && dash_left > 0 {
		state.change(state_dash);
		return;
	}
	
	if buffer_jump > 0 {
		if grace > 0 {
			if dash_grace > 0 {
				action_dashjump(_kh == 0 && dash_dir_y == 1 ? dir : _kh);
			} else {
				action_jump();
			}
		} else {
			var _close = actor_collision(x, y + 24) ||
				get_check_wall(-1, 20) ||
				get_check_wall(1, 20);
			_close = _close && !get_check_death(x, y + 24);
			if _close && dash_grace > 0 {
				dash_grace = 2;
			}
			if dash_grace > 0 && dash_dir_y != -1 && 
				(!_close || dash_dir_y == 0) &&
				!get_check_wall(sign(x_vel), 6) {
				action_dashjump(_kh == 0 && dash_dir_y == 1 ? dir : _kh);
			} else if dash_grace_kick > 0 && dash_dir_y == -1 && _kv == -1 {
				if get_check_wall(dir) {
					action_dashjump_wall(_kh, dir);
				} else if get_check_wall(-dir) {
					action_dashjump_wall(_kh, -dir);
				}
			} else {
				if get_check_wall(1) || get_check_wall(-1) {
					action_walljump();
				}
			}
		}
	}
	
	if get_check_water(x, y) {
		state.change(state_swim);
		return;
	}
	
});

state_ledge = state_base.add();
state_ledge.set("enter", function(){
	hold_jump_key_timer = 0;
	hold_jump_vel = defs.terminal_vel;
	hold_jump_vel_timer = 0;
})
.set("leave", function(){
})
.set("step", function() {
	
	var _kh = INPUT.check("right") - INPUT.check("left");
	var _kv = INPUT.check("down") - INPUT.check("up");
	
	x_vel = 0;
	
	y_vel = 0;
	if !actor_collision(x + dir, y - 22) {
		y_vel = 1
	} else {
		if !actor_collision(x + dir, y - 20) {
			y_vel = -1
		}
	}
	
	action_anim_ledge();
	
	if buffer_dash > 0 && dash_left > 0 {
		state.change(state_dash);
		return;
	}
	
	if buffer_jump > 0 {
		action_walljump();
		state.change(state_free);
		return;
	}
	
	if !get_check_wall(dir, 1) {
		x_vel += get_lift_x();
		y_vel += get_lift_y();
		state.change(state_free);
		return;
	}
	
	if !INPUT.check("grab") {
		state.change(state_free);
		return;
	}
	
});


action_dash_end = function() {

	if y_vel < 0 {
		y_vel = dash_dir_y * 3;
	}
	
	if dash_dir_y == 0 {
		x_vel = max(abs(dash_pre_x_vel), 3) * sign(x_vel);
		
		hold_jump_key_timer = 12;
		hold_jump_vel = defs.terminal_vel;
		hold_jump_vel_timer = 12;
	} else if dash_dir_y == -1 {
		x_vel = max(abs(dash_pre_x_vel), 3) * sign(x_vel);
		
		hold_jump_key_timer = 24;
		hold_jump_vel = defs.terminal_vel;
		hold_jump_vel_timer = 24;
	} else if dash_dir_y == 1 {
		if sign(dash_dir_x_vel) == sign(dash_pre_x_vel) {
			x_vel = max(lerp(abs(dash_pre_x_vel), abs(dash_dir_x_vel) - 1, 0.1), 8) * sign(x_vel);
		} else {
			x_vel = max(lerp(abs(dash_pre_x_vel), abs(dash_dir_x_vel) - 1, 0.1 + 0.8 * clamp(1 - (dash_stale - 2) / 3, 0, 1)), 8) * sign(x_vel);
		}
	}
	
};

state_dash = state_base.add();
state_dash.set("enter", function() {
	
	game_set_pause(3);
	
	buffer_dash = 0;
	dash_left = max(0, dash_left - 1);
	
	dash_pre_x_vel = x_vel;
	dash_pre_y_vel = y_vel;
	
	dash_dir_x = 0;
	dash_dir_y = 0;
	
	dash_dir_x_vel = 0;
	dash_dir_y_vel = 0;
	
	x_vel = 0;
	y_vel = 0;
	
	hold_jump_key_timer = 0;
	hold_jump_vel = defs.terminal_vel;
	hold_jump_vel_timer = 0;
	
	dash_timer = 6;
	dash_frame = 0; // this is stupid
	dash_grace = 14;
	dash_recover = 10;
	
	dash_stale += 1;
	
	dash_jump = false;
	
	game_sound_play(sfx_dash);
	
})
.set("leave", function() {
	
})
.set("step", function() {
	
	var _kh = INPUT.check("right") - INPUT.check("left");
	var _kv = INPUT.check("down") - INPUT.check("up");
	
	if dash_frame == 0 {
		
		if _kh != 0 {
			dir = _kh;
		}
		
		if false {
			// allow dash
			if _kh == 0 && _kv == 0 {
				dash_dir_x = dir;
			} else {
				dash_dir_x = _kv == 1 ? _kh : dir;
			}
			dash_dir_y = _kv;
		} else {
			if _kh == 0 {
				dash_dir_x = dir;
			} else {
				dash_dir_x = _kh;
			}
			dash_dir_y = _kv;
		}
		
		if dash_dir_x != 0 {
			dir = dash_dir_x;
		}
		
		var _dir = point_direction(0, 0, dash_dir_x, dash_dir_y);

		x_vel = 0;
		y_vel = 0;
		
		x_vel = abs(dash_pre_x_vel) * dash_dir_x;
		
		x_vel += lengthdir_x(7, _dir);
		y_vel += lengthdir_y(7, _dir);
		
		if dash_dir_y == -1 {
			dash_grace_kick = 16;
			y_vel *= 0.8;
		}
		
		dash_dir_x_vel = x_vel;
		dash_dir_y_vel = y_vel;
		
		if onground && INPUT.check("down") {
			nat_crouch(true);
		} else {
			if get_can_uncrouch() {
				nat_crouch(false);
			}
		}
		
		action_anim_dash();
		
	}
	
	dash_frame += 1;
	dash_timer -= 1;
	
	
	// @todo: maybe this sucks
	if dash_jump {
		if grace > 0 {
			if dash_dir_y != -1 {
				action_dash_end();
				action_dashjump(_kh == 0 && dash_dir_y == 1 ? dir : _kh);
				state.change(state_free);
				return;
			}
		} else if get_check_wall(dir) { 
			action_dash_end();
			if dash_dir_y == -1 && _kv == -1 {
				action_dashjump_wall(_kh, dir);
			} else {
				action_walljump();
			}
			state.change(state_free);
			return;
		} else {
			if dash_timer <= 0 && (dash_dir_y != -1 || _kh != dir) {
				action_dash_end();
				action_dashjump(_kh == 0 && dash_dir_y == 1 ? dir : _kh);
				state.change(state_free);
				return;
			}
		}
		dash_jump = false;
	}
	
	if buffer_jump > 0 {
		if grace > 0 {
			if dash_dir_y != -1 {
				dash_jump = true;
				dash_timer += 1;
				game_set_pause(2);
			}
		} else if get_check_wall(dir) { 
			dash_jump = true;
			dash_timer += 1;
			game_set_pause(2);
		} else {
			if dash_timer <= 0 && (dash_dir_y != -1 || _kh != dir) {
				dash_jump = true;
				dash_timer += 1;
				game_set_pause(2);
			}
		}
	}
	
	if dash_timer <= 0 {
		action_dash_end();
		state.change(state_free);
		return;
	}
	
});

state_swim = state_base.add();
state_swim.set("enter", function() {
})
state_swim.set("step", function() {
	
	var _kh = INPUT.check("right") - INPUT.check("left");
	var _kv = INPUT.check("down") - INPUT.check("up");
	
	if get_can_uncrouch() {
		nat_crouch(false);
	}
	
	if _kh != 0 {
		dir = _kh;
	}
	
	grace = defs.grace;
	grace_y = y;
	
	dash_left = defs.dash_total;
	
	var _spd = 5;
	
	var _x_vel = _spd * _kh;
	var _y_vel = _spd * _kv;
	if _kh != 0 && _kv != 0 {
		var _factor = sqrt(2) / 2;
		_x_vel *= _factor;
		_y_vel *= _factor;
	}
	
	var _x_accel = 0.3;
	var _y_accel = 0.3;
	
	if abs(x_vel) > abs(_x_vel) && sign(x_vel) == _kh {
		_x_accel = 0.04;
	}
	if abs(y_vel) > abs(_y_vel) && sign(y_vel) == _kv {
		_y_accel = 0.04;
	}
	
	x_vel = approach(x_vel, _x_vel, _x_accel);
	y_vel = approach(y_vel, _y_vel, _y_accel);
	
	if !get_check_water(x, y) {
		if y_vel < 0 {
			y_vel *= 0.95;
			hold_jump_key_timer = 8;
			hold_jump_vel = y_vel;
			hold_jump_vel_timer = 2;
		}
		state.change(state_free);
		return;
	}
	
	if buffer_dash > 0 {
		state.change(state_swim_bullet);
		return;
	}
	
	if buffer_jump > 0 {
		action_jump();
		return;
	}
	
});

state_swim_bullet = state_base.add();
state_swim_bullet.set("enter", function() {
	game_set_pause(4);
	
	buffer_dash = 0;
	
	swim_pre_x_vel = x_vel;
	swim_pre_y_vel = y_vel;
	
	// for anim
	swim_dir = point_direction(0, 0, x_vel, y_vel);
	
	x_vel = 0;
	y_vel = 0;
	
	swim_frame = 0;
	
})
.set("step", function() {
	
	var _kh = INPUT.check("right") - INPUT.check("left");
	var _kv = INPUT.check("down") - INPUT.check("up");
	
	var _kh_r = INPUT.check_raw("horizontal");
	var _kv_r = INPUT.check_raw("vertical");
	
	if swim_frame == 0 {
		if _kh == 0 && _kv == 0 {
			swim_dir = point_direction(0, 0, swim_pre_x_vel == 0 ? dir : swim_pre_x_vel, swim_pre_y_vel);
		} else {
			swim_dir = point_direction(0, 0, _kh, _kv);
		}
		swim_spd = max(point_distance(0, 0, swim_pre_x_vel, swim_pre_y_vel), 8);
	}
	
	if get_can_uncrouch() {
		nat_crouch(false);
	}
	
	var _push_x = get_check_water(x + 16, y) - get_check_water(x - 16, y);
	var _push_y = get_check_water(x, y + 24) - get_check_water(x, y - 24);
	
	if _kh != 0 {
		dir = _kh;
	}
	
	dash_left = defs.dash_total;

	var _k_dir = point_direction(0, 0, _kh_r, _kv_r)
	
	var _dir_target = _k_dir;
	if _kh == 0 && _kv == 0 {
		_dir_target = swim_dir;
	}
	var _dir_diff = angle_difference(swim_dir, _dir_target);
	
	var _spd_target_normal = point_distance(0, 0, _kh_r, _kv_r);
	var _dir_accel = 2;
	
	swim_spd = approach(swim_spd, max(swim_spd, 8), 1);
	_dir_accel = map(swim_spd, 8, 24, 4, 1);
	_dir_accel = clamp(_dir_accel, 1, 4);
	
	swim_dir -= clamp(round(sign(_dir_diff) * _dir_accel), -abs(_dir_diff), abs(_dir_diff));
	
	x_vel = lengthdir_x(swim_spd, swim_dir) + _push_x;
	y_vel = lengthdir_y(swim_spd, swim_dir) + _push_y;
	
	if !get_check_water(x, y) {
		grace = defs.grace;
		grace_y = y;
		if y_vel <= 0 {
			y_vel *= 0.95;
			hold_jump_key_timer = 24;
			hold_jump_vel = y_vel;
			hold_jump_vel_timer = 2;
		}
		state.change(state_free);
		return;
	}
	
	if buffer_dash > 0 {
		state.change(state_swim_bullet);
		return;
	}
	
	swim_frame += 1;
	
});

state_menu = state_base.add();
state_menu.set("enter", function() {
	with global.game.menu system.open(page_none);
})
.set("step", function() {
	x_vel = approach(x_vel, 0, defs.move_accel);
	y_vel = approach(y_vel, defs.terminal_vel, defs.gravity);
	
	buffer_dash = 0;
	buffer_jump = 0;
	
	// @todo: this kinda sucks
	// die
	global.game.menu.system.update();
	
	if array_length(global.game.menu.system.stack) == 0 {
		global.game.menu.system.stop();
		state.change(state_free);
		return;
	}
	
	if !place_meeting(x, y, obj_checkpoint) && !place_meeting(x, y, obj_checkpoint_dyn) {
		global.game.menu.system.stop();
		state.change(state_free);
		return;
	}
	
});

squish = function(_data) {
	
	if !instance_exists(_data.pusher) {
		game_player_kill();
		return;
	}
	
	// since squish only gets calls when solids push actors, _data.pusher.collidable must be false.
	// it's safe to re-enable it so long as it is set back to false at the end of the function
	
	_data.pusher.collidable = true;
	
	var _crouched = false;
	if !nat_crouch() && state.is(state_free) {
		nat_crouch(true);
		_crouched = true;
		
		// this looks so fucking stupid
		if !actor_collision(x, y) {
			scale_x = 1.2;
			scale_y = 0.8;
			_data.pusher.collidable = false;
			return;
		}
		if !actor_collision(_data.target_x, _data.target_y) {
			x = _data.target_x;
			y = _data.target_y;
			scale_x = 1.2;
			scale_y = 0.8;
			_data.pusher.collidable = false;
			return;
		}
	}
	
	var _amount = 12;
	
	var _out = false;
	
	// todo: a particular edge case happens sometimes due to this not detecting diagonal escape positions
	for (var i = 0; i < _amount * 2; i++) {
		var _d = (i % 2 == 0 ? 1 : -1) * floor((i + 2) / 2);
		if !actor_collision(x + _d, y) {
			x += _d;
			_out = true;
			break;
		}
		if !actor_collision(x, y + _d) {
			y += _d;
			_out = true;
			break;
		}
		if !actor_collision(_data.target_x + _d, _data.target_y) {
			x = _data.target_x + _d;
			y = _data.target_y;
			_out = true;
			break;
		}
		if !actor_collision(_data.target_x, _data.target_y + _d) {
			x = _data.target_x;
			y = _data.target_y + _d;
			_out = true;
			break;
		}
	}
	
	if _out {
		if !_crouched && get_can_uncrouch() {
			nat_crouch(false);
		}
		_data.pusher.collidable = false;
		return;
	}
	
	_data.pusher.collidable = false;
	game_player_kill();
};

riding = function(_solid) {
	return place_meeting(x, y + 1, _solid) ||
		(state.is(state_ledge) && place_meeting(x + dir, y, _solid));
};

cam = function(_cam) {
	
	if state.is(state_free) && onground {
		cam_ground_x = x + dir * 64;
		cam_ground_y = y - 32;
	}
	
	var _dist = point_distance(cam_ground_x, cam_ground_y, x, y);
	
	var _x = x + power(abs(x_vel), 1.4) * sign(x_vel);
	var _y = y - 32;
	
	/*
	if state.is(state_menu) {
		_x += 48 + (array_length(menu.stack) - 1) * 12;
		_y += -4;
	}*/
	
	_x = lerp(cam_ground_x, _x, 1 - max(0, 1 - power(_dist / 64, 2)) * 0.0);
	_y = lerp(cam_ground_y, _y, 1 - max(0, 1 - power(_dist / 128, 2)) * 0.8);
	
	var _ = _cam.constrain(_x, _y);
	_cam.move(_.x, _.y);
}

outside = function() { return false; };


state.change(state_free);

