
event_inherited();


// behaviour

defs = {
	
	move_speed: 2,
	move_accel: 0.5,
	move_slowdown: 0.1,
	
	boost_limit_x: 9,
	boost_limit_y: 3,
	
	jump_vel: -4,
	jump_move_boost: 0.2,
	terminal_vel: global.defs.terminal_vel,
	
	jump_short_vel: -3,
	
	gravity: 0.45,
	gravity_hold: 0.2,
	gravity_peak: 0.1,
	gravity_peak_thresh: 0.36,
	
	gravity_damp: 0.8,
	
	wall_distance: 4,
	
	climb_speed: 2,
	climb_accel: 1,
	climb_slide: 0.1,
	climb_leave: 8,
	
	dash_timer: 6,
	dash_total: 1,
	
	buffer: 12,
	grace: 4,
	
	anim_dive_time: 20,
	anim_jab_time: 20,
	anim_longjump_time: 30,
	
	
};

input = {
	left: false,
	right: false,
	up: false,
	down: false,
	jump: false,
	jump_pressed: false,
	jump_released: false,
	dash: false,
	dash_pressed: false,
	dash_released: false,
	hold: false,
	hold_pressed: false,
	hold_released: false,
};

anim = new AnimController()
.add("idle", new AnimLevel([0]))
.add("walk", new AnimLevel([3, 1, 4, 2], 12)) // todo: more frames. make subtle variations of these two
.add("jump", new AnimLevel([5]))
.add("fall", new AnimLevel([6]))
.add("dive", new AnimLevel([7]))
.add("jab", new AnimLevel([11]))
.add("longjump", new AnimLevel([8]))

.meta_default({
	x: -2, y: -16,
	eye_x: 2, eye_y: -29,
	front: false
})
.meta_items([1, 2], {
	y: -15
})
.meta_items([5, 6], {
	y: -17
})
.meta_items([7], {
	x: -4, y: -21,
	front: true
})
.meta_items([8], {
	x: -8, y: -16
})
.meta_items([11], {
	x: 3, y: -11
})


event = new Event()
.add("ground", function(){
	anim_longjump_timer = 0;
})
.add("jump", function(){
	anim_dive_timer = 0;
	anim_jab_timer = 0;
})
.add("jumpdash", function(){
	anim_longjump_timer = defs.anim_longjump_time;
})
.add("dive", function(){
	if y_vel > 0
		anim_dive_timer = defs.anim_dive_time;
	else
		anim_jab_timer = defs.anim_jab_time;
})


// properties

scale_x = 0;
scale_y = 0;

dir = 1;

grace = 0;
grace_y = y;
grace_solid = noone;
buffer = 0;
buffer_dash = 0;

gravity_hold_peak = 0;
gravity_hold = 0;

key_hold = 0;
key_hold_timer = 0;

momentum_grace = 0;
momentum_grace_amount = 0;

climb_away = 0;

dash_dir_x = 0;
dash_dir_x_vel = 0;
dash_dir_y = 0;
dash_dir_y_vel = 0;
dash_timer = 0;
dash_grace = 0;
dash_recover = 0;

dash_left = 0;

holding = noone;
hold_cooldown = 0;
hold_throw_x = 0;
hold_throw_y = 0;

anim_dive_timer = 0;
anim_jab_timer = 0;
anim_longjump_timer = 0;

cam_ground_x = x;
cam_ground_y = y;


depth = -10;
mask_index = spr_debug_player;

tail_length = 12;
tail = yarn_create(tail_length, function(_p, i){
	//_p.len = min(power(max(i - 4, 0) , 1.12) + 4, 8)
	_p.length = 4;
	
	_p.x = x
	_p.y = y + i * 6
		
	_p.size = max(parabola_mid(3, 7, 6, i) + 3, 6)
	_p.round = floor(clamp(i / (tail_length / 4), 1, 4))
})

draw_tail = function(_tip = #ff00ff, _blend = c_white){
	self._tip = _tip;
	self._blend = _blend;
	tail.loop_reverse(function(_p, j) {
		var _c = merge_color(c_white, _tip, clamp(j - 3, 0, tail_length) / tail_length);
		_c = multiply_color(_c, _blend);
		draw_sprite_ext(
			spr_player_tail, 0, 
			round_ext(_p.x, _p.round), round_ext(_p.y, _p.round), 
			//round_ext(_p.x, 0), round_ext(_p.y, 0), 
			_p.size / 16, _p.size / 16, 
			0, _c, 1
		);
	})
}


checkWall = function(_dir){
	return actor_collision(x + _dir * defs.wall_distance, y);
}

checkDeath_point = function(_x, _y, _xv = 0, _yv = 0) {
	
	_xv = round(_xv);
	_yv = round(_yv);
	
	static _size = 5;
	
	for (var i = 0; i < array_length(level.levels); i++) {
		
		var _tm = level.levels[i].spikes_tiles;
		var _tile = tilemap_get_at_pixel(_tm, _x, _y);
		
		if _tile == 0 continue;
		
		switch _tile {
			case 1:
				if !point_in_rectangle(_x % TILESIZE, _y % TILESIZE, 0, 0, _size, 16)
					break;
				if _xv > 0 break;
				return true;
			case 2:
				if !point_in_rectangle(_x % TILESIZE, _y % TILESIZE, 0, 16 - _size, 16, 16)
					break;
				if _yv < 0 break;
				return true;
			case 3:
				if !point_in_rectangle(_x % TILESIZE, _y % TILESIZE, 16 - _size, 0, 16, 16)
					break;
				if _xv < 0 break;
				return true;
			case 4:
				if !point_in_rectangle(_x % TILESIZE, _y % TILESIZE, 0, 0, 16, _size)
					break;
				if _yv > 0 break;
				return true;
		}
		
	}
	
	return false;
	
}

checkDeath = function(_x, _y){
	
	var _inst = instance_place(_x, _y, obj_spike);
	with _inst {
		if object_index == obj_spike_up && other.y_vel >= 0 return true;
		if object_index == obj_spike_down && other.y_vel <= 0 return true;
		if object_index == obj_spike_left && other.x_vel >= 0 return true;
		if object_index == obj_spike_right && other.x_vel <= 0 return true;
	}
	
	var _lx = x, _ly = y;
	
	x = _x;
	y = _y;
	
	var _out = false 
		|| checkDeath_point(bbox_left, bbox_top, x_vel, y_vel)
		|| checkDeath_point(bbox_right - 1, bbox_top, x_vel, y_vel)
		|| checkDeath_point(bbox_left, bbox_bottom - 1, x_vel, y_vel)
		|| checkDeath_point(bbox_right - 1, bbox_bottom - 1, x_vel, y_vel)
	
	x = _lx;
	y = _ly;
	
	return _out;
	
	
}

hold_begin = function(_inst){
	holding = _inst;
	anim_holding = 0;
			
	holding.state.change(holding.state_held)
			
	state.change(state_free);
}
hold_end = function(){
	if !holding return;
	holding.state.change(holding.state_free);
	holding = noone;
}

#region jump

jump = function(){
	
	buffer = 0
	if grace && grace_target {
		if grace_target.object_index == obj_box {
			grace_target.x_vel += sign(x_vel)
			grace_target.y_vel = 4;
		}
		if grace_target.object_index == obj_ball {
			//grace_target.x_vel = 0;
			grace_target.y_vel = 4;
		}
	}
	grace = 0;
	grace_target = noone;
	gravity_hold = 0;
	gravity_hold_peak = 0;
	//actor_move_y(grace_y - y)
	
	dash_left = defs.dash_total;

	y_vel = defs.jump_vel;
	x_vel += (defs.jump_move_boost + defs.move_accel) * sign(x_vel);
	
	if x_lift == 0 && y_lift == 0 {
		with instance_place(x, y + 1, obj_Solid) {
			other.x_lift = x_lift;
			other.y_lift = y_lift;
		}
	}
	x_vel += x_lift;
	y_vel += y_lift;
	
	scale_x = 0.8;
	scale_y = 1.2;
	
	event.call("jump")
	
	state.change(state_free);
	
}

jumpdash = function(){
	
	var _kh = input.right - input.left;
	var _kv = input.down - input.up;
	
	if grace && grace_target {
		if grace_target.object_index == obj_box {
			dash_left = defs.dash_total;
			grace_target.x_vel += sign(x_vel) * 3
			grace_target.y_vel = 4;
		}
		if grace_target.object_index == obj_ball {
			dash_left = defs.dash_total;
			grace_target.x_vel += sign(x_vel) * 3
			grace_target.y_vel = 4;
		}
	}
	grace = 0;
	grace_target = noone;
	dash_grace = 0;
	buffer = 0;
	gravity_hold = 0;
	gravity_hold_peak = 0;
			
	if dash_dir_y == 0 {
		
		if _kh != dash_dir_x {
			y_vel = -5.4;
			x_vel = dash_dir_x_vel * 0.4
			x_vel = max(abs(x_vel), defs.move_speed) * sign(x_vel);
		} else {
			y_vel = defs.jump_vel;
			x_vel = dash_dir_x_vel * 0.8
			x_vel = max(abs(x_vel), defs.move_speed) * sign(x_vel);
		}
		
	} else {
		y_vel = -3
		x_vel = abs(dash_dir_x_vel) * 0.7 * sign(_kh == 0 ? sign(x_vel) : _kh)
		x_vel += (_kh == 0 ? dir : _kh) * 4
	}
	
	if x_lift == 0 && y_lift == 0 {
		with instance_place(x, y + 1, obj_Solid) {
			other.x_lift = x_lift;
			other.y_lift = y_lift;
		}
	}
	x_vel += x_lift;
	y_vel += y_lift;
	
	scale_x = 0.9;
	scale_y = 1.1;
	
	event.call("jump")
	event.call("jumpdash")
	
	state.change(state_free);
	
}

wallbounce = function(_dir){
	
	buffer = 0
	grace = 0;
	dash_grace = 0;
	gravity_hold = 0;
	gravity_hold_peak = 0;
	
	dash_left = defs.dash_total
	
	y_vel = -3
	
	x_vel = 2 * _dir
	x_vel += _dir * 4
	key_hold = sign(x_vel);
	key_hold_timer = 5
	
	x_vel += x_lift;
	y_vel += y_lift;
	
	event.call("jump")
	
	state.change(state_free);
	
}

walljump = function(_dir){
	
	buffer = 0
	grace = 0;
	gravity_hold = 0;
	gravity_hold_peak = 0;
	//actor_move_y(grace_y - y)
	
	dash_left = defs.dash_total;

	y_vel = defs.jump_vel;
	//x_vel += (defs.jump_move_boost + defs.move_accel) * _dir;
	
	if x_lift == 0 && y_lift == 0 {
		with instance_place(x + _dir * defs.wall_distance, y, obj_Solid) {
			other.x_lift = x_lift;
			other.y_lift = y_lift;
		}
	}
	x_vel += x_lift;
	y_vel += y_lift;
	
	scale_x = 0.8;
	scale_y = 1.2;
	
	event.call("jump")
	
	state.change(state_free);
	
};

#endregion

// state machine

state = new State();

state_base = state.add()
.set("step", function(){
	
	input.left = keyboard_check(vk_left);
	input.right = keyboard_check(vk_right);
	input.up = keyboard_check(vk_up);
	input.down = keyboard_check(vk_down);

	input.jump = keyboard_check(ord("X"));
	input.jump_pressed = keyboard_check_pressed(ord("X"));
	input.jump_released = keyboard_check_released(ord("X"));
	
	input.dash = keyboard_check(ord("Z"));
	input.dash_pressed = keyboard_check_pressed(ord("Z"));
	input.dash_released = keyboard_check_released(ord("Z"));
	
	input.hold = keyboard_check(vk_shift);
	input.hold_pressed = keyboard_check_pressed(vk_shift);
	input.hold_released = keyboard_check_released(vk_shift);
	
	if input.jump_pressed buffer = defs.buffer + 1;
	if input.dash_pressed buffer_dash = defs.buffer + 1;
	
	if place_meeting(x, y, obj_flag_stop) {
		show_debug_message("e")
		// lazy
		var _names = struct_get_names(input);
		for (var i = 0; i < array_length(_names); i++) {
			input[$ _names[i]] = false;
		}
		buffer = 0;
		buffer_dash = 0;
	}
	
	if game_paused() {
		return;
	}
	
	buffer -= 1;
	buffer_dash -= 1;
	grace -= 1;
	gravity_hold -= 1;
	gravity_hold_peak -= 1;
	key_hold_timer -= 1;
	dash_grace -= 1;
	dash_recover -= 1;
	hold_cooldown -= 1;
	
	if !grace {
		grace_target = noone;
	}

	scale_x = lerp(scale_x, 1, 0.2);
	scale_y = lerp(scale_y, 1, 0.2);
	
	x_lift = clamp(x_lift, -defs.boost_limit_x, defs.boost_limit_x);
	y_lift = clamp(y_lift, -defs.boost_limit_y, 0);
	
	state.child();
	
	var _d = 0, _amount = 0;
	
	if y_vel < 0 {
		_d = 0;
		_amount = 8;
		if actor_collision(x, y + y_vel)
			for (_d = 1; _d < _amount; _d++) {
				if actor_collision(x - _d, y + y_vel) {
				} else break;
			}
		if _d != _amount
			actor_move_x(-_d)
		
		_d = 0;
		if actor_collision(x, y + y_vel)
			for (_d = 1; _d < _amount; _d++) {
				if actor_collision(x + _d, y + y_vel) {
				} else break;
			}
		if _d != _amount
			actor_move_x(_d)
	}
	
	actor_move_y(y_vel, function(){
		if y_vel > 1.5 {
			scale_x = 1.2;
			scale_y = 0.8;
		}
		y_vel = 0;
	});
	
	
	if state.is(state_dash) {
		_d = 0;
		_amount = 8;
		if actor_collision(x + x_vel, y)
			for (_d = 1; _d < _amount; _d++) {
				if actor_collision(x + x_vel, y + _d) {
				} else break;
			}
		if _d != _amount
			actor_move_y(_d)
	}

	actor_move_x(x_vel, function(){
		x_vel = 0;
	});
	
	
	if state.is(state_free) || state.is(state_dash) {
		
		if anim_jab_timer && !buffer {		
			var _inst = instance_place(x, y, [obj_box, obj_ball]);
			if _inst {
				game_set_pause(4)
				
				if dash_dir_y == 0 {
					_inst.x_vel = clamp(abs(_inst.x_vel + sign(x_vel) * 2), 4, 8) * sign(x_vel);
					_inst.y_vel = clamp(_inst.y_vel - 1, -3, -4);
				} else {
					_inst.x_vel = clamp(abs(_inst.x_vel + sign(x_vel) * 1), 3, 6) * sign(x_vel);
					_inst.y_vel = clamp(_inst.y_vel - 1, -5, -7);
				}
				
				anim_jab_timer = 0;
			}
		}
		
		var _inst = instance_place(x, y, obj_dash)
		if dash_left < defs.dash_total && _inst && _inst.state.is(_inst.state_active) {
			game_set_pause(4)
			
			dash_left = defs.dash_total;
			
			_inst.state.change(_inst.state_recover);
		}
		
		var _inst = collision_circle(x, y, 32, [obj_box, obj_ball], false, true);
		if _inst && !holding && input.hold && !hold_cooldown {
			game_set_pause(5);
			hold_begin(_inst)
		}
		
	}
	
	if holding {
		anim_holding = approach(anim_holding, 1, 0.1)
		
		var _tp = tail.points[4] //[floor(array_length(tail.points) / 2)];
		var _cx = holding.x;
		var _cy = holding.y + 6;
		var _tx = round(lerp(_cx, _tp.x, anim_holding))
		var _ty = round(lerp(_cy, _tp.y, anim_holding))
		
		with holding {
			x_vel = other.x_vel;
			y_vel = other.y_vel;
			actor_move_x(_tx - _cx)
			actor_move_y(_ty - _cy)
		}
		
	}
	
	
	if checkDeath(x, y) {
		game_set_pause(10);
		
		instance_destroy();
		instance_create_layer(x, y, "Instances", obj_player_death);
	}
	
	
	// this will almost certainly cause an issue later. 
	// todo: figure out how to reset a_lift when touching tiles
	x_lift = 0;
	y_lift = 0;
	
})

state_free = state_base.add()
.set("step", function(){

	var _kh = input.right - input.left;
	var _kv = input.down - input.up;
	
	// x direction logic
	
	var _kh_move = _kh;
	if key_hold_timer _kh_move = key_hold;
	
	var _x_accel = 0;
	if abs(x_vel) > defs.move_speed && _kh_move == sign(x_vel) {
		_x_accel = defs.move_slowdown;
		if !actor_collision(x, y + 1)
			momentum_grace = 6;
	} else {
		_x_accel = defs.move_accel;
	}
	momentum_grace -= 1;
	if momentum_grace && _kh_move != sign(x_vel) {
		_x_accel = 0;
	}
	
	x_vel = approach(x_vel, _kh_move * defs.move_speed, _x_accel);
	if _kh != 0
		dir = _kh;
	
	// y direction logic
	
	var _y_accel = 0;

	if input.jump {
		if abs(y_vel) < defs.gravity_peak_thresh {
			// peak jump
			_y_accel = defs.gravity_peak;
		} else {
			_y_accel = defs.gravity_hold;
		}
	} else {
		_y_accel = defs.gravity;
	}
	if gravity_hold > 0 {
		_y_accel = defs.gravity_hold;
	}
	if gravity_hold_peak > 0 {
		_y_accel = defs.gravity_peak;
	}

	if input.jump_released && y_vel < 0 {
		// release jump damping
		y_vel *= defs.gravity_damp;
	}

	y_vel += _y_accel

	y_vel = min(y_vel, defs.terminal_vel);
	
	var _wall = actor_collision(x + defs.wall_distance, y) - actor_collision(x - defs.wall_distance, y);
	
	var _inst = collision_circle(x, y, 14, [obj_box, obj_ball], false, true);
	if _inst {
		grace = defs.grace;
		grace_target = _inst;
	}
	if actor_collision(x, y + 1) {
		grace = defs.grace;
		grace_target = noone;
		grace_y = y;
		
		if dash_recover < 0
			dash_left = defs.dash_total;
		
		event.call("ground")
	}
	
	
	// hell
	if buffer > 0 {
		
		if grace > 0 {
			if dash_grace > 0 {
				jumpdash()
			} else {
				jump()
			}
		} else {
			
			var _close = actor_collision(x, y + 32)
			if _close && dash_grace > 0 {
				dash_grace = 2;
			}
			if dash_grace > 0 && ((_close && grace > 0) || !_close || dash_dir_y == 0) && !checkWall(sign(x_vel)) {
				jumpdash()
			} else {
				
				if checkWall(1) {
					if dash_grace > 0 && _kh != dir {
						wallbounce(-1);
					} else {
						walljump(-1);
					}
				} else if checkWall(-1) {
					if dash_grace > 0 && _kh != dir {
						wallbounce(1);
					} else {
						walljump(1);
					}
				}
				
			}
			
		}
		
	}
	
	if buffer_dash > 0 && dash_left > 0 {
		game_set_pause(3);
		state.change(state_dashset);
		return;
	}
	
	if holding && !input.hold {
		game_set_pause(5);
		state.change(state_throw)
		return;
	}
	
})

state_throw = state_base.add()
.set("enter", function(){
	
	var _kh = input.right - input.left;
	var _kv = input.down - input.up;
	
	key_hold = _kh;
	key_hold_timer = 6;
	
	hold_throw_x = _kh;
	hold_throw_y = _kv;
})
.set("step", function(){
	
	var _kh = input.right - input.left;
	var _kv = input.down - input.up;
	
	_kh = hold_throw_x;
	_kv = hold_throw_y;
	
	holding.x = x + dir * 4;
	holding.y = y - 12
	
	var _dir = _kh != 0 ? _kh : dir;
	
	if _kh == 0 && _kv == 1 {
		holding.x = x;
		holding.y = y - 4;
		holding.x_vel = 0;
		holding.y_vel = 4;
	} else if _kv == 1 {
		holding.x_vel = _dir * 3 + x_vel / 2;
		holding.y_vel = 4;
	} else if _kh == 0 && _kv == -1 {
		holding.x_vel = 0;
		holding.y_vel = -7;
	} else if _kv == -1 {
		holding.x_vel = _dir * 3 + x_vel / 2;
		holding.y_vel = -5;
	} else {
		holding.x_vel = _dir * 5 + x_vel / 2;
		holding.y_vel = -3;
	}
		
	holding.x_vel = clamp(holding.x_vel, -6, 6)
		
	hold_end()
	
	hold_cooldown = 14;
	grace_target = noone;
	
	state.change(state_free)
})

state_dashset = state_base.add()
.set("step", function(){
	buffer_dash = 0;
	
	var _kh = input.right - input.left;
	var _kv = input.down - input.up;
	
	if _kh == 0
		dash_dir_x = dir;
	else
		dash_dir_x = _kh;
	
	dash_dir_y = _kv;
	
	if _kv == -1 {
		x_vel = dash_dir_x * max(6, 4 + min(abs(x_vel), 4));
		y_vel = defs.jump_vel;
		
		gravity_hold = 9;
		key_hold_timer = 14;
		key_hold = dash_dir_x;
		
		dash_left -= 1;
		
		event.call("dive");
		state.change(state_free);
		
		return;
	}
	
	state.change(state_dash);
})

state_dash = state_base.add()
.set("enter", function(){
	dash_timer = 6;
	dash_left -= 1;
	
	x_vel *= 0.5;
	y_vel = 0;
	var _dir = point_direction(0, 0, dash_dir_x, dash_dir_y);
	dash_dir_x_vel = lengthdir_x(7, _dir);
	dash_dir_y_vel = lengthdir_y(6, _dir);
	x_vel += dash_dir_x_vel;
	y_vel += dash_dir_y_vel;
	
	dir = sign(x_vel)
	
	event.call("dive")
})
.set("leave", function(){
	dash_grace = 8;
	dash_recover = 1;
})
.set("step", function(){
	
	var _kh = input.right - input.left;
	var _kv = input.down - input.up;
	
	if actor_collision(x, y + 1) {
		grace = defs.grace;
		grace_y = y;
	}
	
	//actor_move_y(y_vel);

	//actor_move_x(x_vel);
	
	if buffer > 0 {
		if grace > 0 {
			if _kh == dir {
				jumpdash();
				return;
			}
		} else {
			if checkWall(dir) {
				if _kh != dir
					wallbounce(-dir);
				else
					walljump(-dir);
				return;
			}
		}
	}
	
	dash_timer -= 1;
	if dash_timer <= 0 {
		grace = 0;
		gravity_hold_peak = 8
		
		if dash_dir_y == 0
			x_vel = clamp(x_vel * 0.5, -4, 4);
		else
			x_vel *= 0.8;
		x_vel = max(abs(x_vel), defs.move_speed) * sign(x_vel);
		
		state.change(state_free);
		return;
	}
	
})

state.change(state_free);


riding = function(_solid){
	return place_meeting(x, y + 1, _solid)
}

cam = function(){
	
	if (state.is(state_free) && actor_collision(x, y + 1)) {
		cam_ground_x = x + dir * 32;
		cam_ground_y = y;
	}
	
	var _dist = point_distance(cam_ground_x, cam_ground_y, x, y);
	
	camera.target_x = lerp(cam_ground_x, x, 1 - max(0, 1 - power(_dist / 64, 2)) * 0.2);
	camera.target_y = lerp(cam_ground_y, y, 1 - max(0, 1 - power(_dist / 128, 2)) * 0.8);
	
}



