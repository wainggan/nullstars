
image_xscale = jorp_w;
image_yscale = jorp_h;

event_inherited();

trigger_setup();
glue_parent_setup();

vel = 0;
accel = 0;
time = 0;

progress = 0;

anim_vel = 0;

start_x = x;
start_y = y;

target_x = x;
target_y = y;

with target {
	other.target_x = x;
	other.target_y = y;
}

trigger_set(function() {
	if state.is(state_idle) state.change(state_active);
});

fn_touch = function () {
	if time <= 0 && !reliant {
		trigger_run();
		trigger_send();
	}
};

fn_reset = function(){
	state.change(state_idle);
	progress = 0;
	x = xstart;
	y = ystart;
	glue_parent_moved(x, y);
}

state = new State();

state_idle = state.add();
state_idle.set("enter", function() {
	time = 10;
});
state_idle.set("step", function(){
	
	var _activate = false;
	
	lift_x = 0;
	lift_y = 0;
	
	time -= 1;
	
	progress = 0;
	
});

state_active = state.add();
state_active.set("enter", function () {
	vel = 0;
	accel = 0;
	
	instance_create_layer(x, y, layer, obj_effects_rectpop, {
		width: sprite_width,
		height: sprite_height,
		pad: 16,
		spd: 0.04,
	});
});
state_active.set("step", function () {
	
	var _dist = point_distance(start_x, start_y, target_x, target_y);
	var _dir = point_direction(start_x, start_y, target_x, target_y);
	
	accel += 0.05;
	vel = approach(vel, spd, accel);
	
	anim_vel += min(vel, 5);
	
	progress = approach(progress, 1, vel / _dist);
	
	// todo: this is a pretty ugly hack.
	// probably safe; these get set and unset correctly, but surely theres a
	// safer, more extensible way of doing this, even in gml?
	with obj_lift_attack {
		if !state.is(state_dead) {
			pet.mask_index = spr_none;
			mask_index = sprite_index;
		}
	}
	
	var _to_x = start_x + lengthdir_x(progress, _dir) * _dist;
	var _to_y = start_y + lengthdir_y(progress, _dir) * _dist;
	
	self.fn_move(_to_x - x, _to_y - y, true, lengthdir_x(vel, _dir), lengthdir_y(vel, _dir));
	glue_parent_moved(x, y);
	
	with obj_lift_attack {
		if !state.is(state_dead) {
			pet.mask_index = pet.sprite_index;
			mask_index = spr_none;
		}
	}
	
	if progress == 1 {
		game_camera_set_shake(4, 0.4)
		state.change(state_retract)
	}
});

state_retract = state.add();
state_retract.set("enter", function () {
	vel = 0;
	accel = 0;
	time = 10;
});
state_retract.set("step", function () {
	
	var _dist = point_distance(start_x, start_y, target_x, target_y);
	var _dir = point_direction(start_x, start_y, target_x, target_y);
	
	with obj_lift_attack {
		if !state.is(state_dead) {
			pet.mask_index = spr_none;
			mask_index = sprite_index;
		}
	}
	
	time -= 1;
	if time < 0 {
		accel = approach(accel, 0.04, 0.002);
		vel = approach(vel, global.defs.lift_spd_return, accel);
		
		anim_vel -= vel;
		
		progress = approach(progress, 0, vel / _dist);
		
		var _to_x = start_x + lengthdir_x(progress, _dir) * _dist;
		var _to_y = start_y + lengthdir_y(progress, _dir) * _dist;
		
		self.fn_move(_to_x - x, _to_y - y, true, -lengthdir_x(vel, _dir), -lengthdir_y(vel, _dir));
		glue_parent_moved(x, y);
		
		if progress == 0 {
			game_camera_set_shake(2, 0.4);
			state.change(state_idle);
		}
	}
	
	with obj_lift_attack {
		if !state.is(state_dead) {
			pet.mask_index = pet.sprite_index;
			mask_index = spr_none;
		}
	}
});

state.change(state_idle);

