
image_xscale = jorp_w;
image_yscale = jorp_h;

event_inherited();

trigger_setup();
glue_parent_setup();

vel = 0;
accel = 0;
time = 0;

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

reset = function(){
	state.change(state_idle);
	x = xstart;
	y = ystart;
	glue_parent_moved(x, y);
}

state = new State();

state_idle = state.add()
.set("enter", function() {
	time = 10;
})
.set("step", function(){
	
	var _activate = false;
	
	lift_x = 0;
	lift_y = 0;
	
	time -= 1;
	if time < 0 with obj_player {
		if riding(other) _activate = true;
	}
	
	if _activate {
		if !reliant {
			trigger_run();
			trigger_send();
		}
	}
	
})

state_active = state.add()
.set("enter", function(){
	vel = 0;
	accel = 0;
	
	instance_create_layer(x, y, layer, obj_effects_rectpop, {
		width: sprite_width,
		height: sprite_height,
		pad: 16,
		spd: 0.04,
	});
})
.set("step", function(){
	
	var _dir = point_direction(start_x, start_y, target_x, target_y)
	
	accel += 0.05;
	vel = approach(vel, spd, accel);
	
	anim_vel += min(vel, 5);
	
	solid_move(lengthdir_x(vel, _dir), lengthdir_y(vel, _dir));
	glue_parent_moved(x, y);
	
	if (start_x == target_x || sign(x - target_x) != sign(start_x - target_x))
	&& (start_y == target_y || sign(y - target_y) != sign(start_y - target_y)) {
		solid_move(target_x - x, target_y - y, false);
		glue_parent_moved(x, y);
		game_camera_set_shake(4, 0.4)
		state.change(state_retract)
	}
	
})

state_retract = state.add()
.set("enter", function(){
	vel = 0;
	accel = 0;
	time = 10;
})
.set("step", function(){
	
	var _dir = point_direction(target_x, target_y, start_x, start_y)
	
	time -= 1;
	if time < 0 {
		accel = approach(accel, 0.04, 0.002);
		vel = approach(vel, global.defs.lift_spd_return, accel);
		
		anim_vel -= vel;
		
		solid_move(lengthdir_x(vel, _dir), lengthdir_y(vel, _dir));
		glue_parent_moved(x, y);
	}
	
	if (start_x == target_x || sign(x - start_x) != sign(target_x - start_x))
	&& (start_y == target_y || sign(y - start_y) != sign(target_y - start_y)) {
		solid_move(start_x - x, start_y - y, false);
		glue_parent_moved(x, y);
		game_camera_set_shake(2, 0.4)
		state.change(state_idle)
	}
	
})


state.change(state_idle)

