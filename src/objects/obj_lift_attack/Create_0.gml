
image_xscale = jorp_w;
image_yscale = jorp_h;

event_inherited();

trigger_setup();
glue_parent_setup();

pet = instance_create_layer(x, y, layer, obj_Solid, {
	image_xscale: sprite_width, image_yscale: sprite_height,
});
pet.outside = exists_outside_empty();

squish = function () {
	game_set_pause(2);
	game_camera_set_shake(2, 0.4);
	state.change(state_dead);
};

riding = function () {
	return false;
};
mask_index = spr_none;

accel = 0;
time = 0;

switch dir {
	case "right":
		dir = 0;
		break;
	case "up":
		dir = 1;
		break;
	case "left":
		dir = 2;
		break;
	case "down":
		dir = 3;
		break;
	default:
		throw $"Unknown obj_lift_activate dir value: {dir}";
}

x_vel = 0;
y_vel = 0;

start_x = x;
start_y = y;

reset_polarity_x = 0;
reset_polarity_y = 0;

anim_vel = 0;
anim_sight_x = x; // @todo: bandage
anim_sight_y = y;
anim_frame = 0;
anim_line = 1;

trigger_set(function(){
	if state.is(state_idle) || state.is(state_retract) {
		state.change(state_active);
	}
});

reset = function(){
	state.change(state_idle);
	x = xstart;
	y = ystart;
	glue_parent_moved(x, y);
	reset_polarity_x = 0;
	reset_polarity_y = 0;
	resot = true;
	with pet {
		x = other.x;
		y = other.y;
	}
};


state = new State();

state_dead = state.add();
state_dead.set("enter", function () {
	game_render_particle(x + sprite_width / 2, y + sprite_height / 2, ps_gen_pop);
	pet.mask_index = spr_none;
	mask_index = spr_none;
});
state_dead.set("leave", function () {
	pet.mask_index = pet.sprite_index;
	mask_index = spr_none;
});

state_idle = state.add();
state_idle.set("enter", function () {
	time = 10;
});
state_idle.set("step", function () {
	
	var _activate = false;
	
	pet.lift_x = 0;
	pet.lift_y = 0;
	
	pet.mask_index = spr_none;
	mask_index = sprite_index;
	
	var _check = actor_check_scan(x, y, dir, obj_player);
	anim_sight_x = _check[1].x;
	anim_sight_y = _check[1].y;
	
	anim_frame += 1;
	
	time -= 1;
	if time < 0 _activate = _check[0];
	
	pet.mask_index = pet.sprite_index;
	mask_index = spr_none;
	
	if _activate {
		if !reliant {
			trigger_run();
			trigger_send();
		}
	}
	
});

state_active = state.add();
state_active.set("enter", function () {
	x_vel = 0;
	y_vel = 0;
	accel = 0;
	
	start_x = x;
	start_y = y;
	
	anim_line = 1;
	
	reset_polarity_x = lengthdir_x(1, dir * 90);
	reset_polarity_y = lengthdir_y(1, dir * 90);
	
	instance_create_layer(x, y, layer, obj_effects_rectpop, {
		width: sprite_width,
		height: sprite_height,
		pad: 16,
		spd: 0.04,
	});
});
state_active.set("step", function () {
	
	accel += 0.05;
	x_vel = approach(x_vel, lengthdir_x(spd, dir * 90), accel);
	y_vel = approach(y_vel, lengthdir_y(spd, dir * 90), accel);
	
	anim_vel += min(point_distance(0, 0, x_vel, y_vel), 5);
	anim_frame += 2;
	
	pet.mask_index = spr_none;
	mask_index = sprite_index;
	
	static __collide = function () {
		game_camera_set_shake(4, 0.4);
		state.change(state_retract);
	};
	
	actor_move_x(x_vel, __collide);
	actor_move_y(y_vel, __collide);
	glue_parent_moved(x, y);
	
	pet.mask_index = pet.sprite_index;
	mask_index = spr_none;
	
	with pet {
		solid_move(other.x - x, other.y - y, true, other.x_vel, other.y_vel);
	}
});

state_retract = state.add();
state_retract.set("enter", function () {
	x_vel = 0;
	y_vel = 0;
	accel = 0;
	time = 10;
});
state_retract.set("leave", function () {
});
state_retract.set("step", function () {
	
	time -= 1;
	if time < 0 {
		accel = approach(accel, 0.04, 0.002);
		x_vel = approach(x_vel, -lengthdir_x(global.defs.lift_spd_return, dir * 90), accel);
		y_vel = approach(y_vel, -lengthdir_y(global.defs.lift_spd_return, dir * 90), accel);
		
		anim_vel -= point_distance(0, 0, x_vel, y_vel);
		anim_frame += 1;
		
		pet.mask_index = spr_none;
		mask_index = sprite_index;
		
		static __collide = function () {
			game_camera_set_shake(2, 0.4);
			state.change(state_idle);
		};
		
		var _off_x = min(x_vel, start_x - x);
		var _off_y = min(y_vel, start_y - y);
		
		actor_move_x(_off_x, __collide);
		actor_move_y(_off_y, __collide);
		
		glue_parent_moved(x, y);
		
		pet.mask_index = pet.sprite_index;
		mask_index = spr_none;
		
		with pet {
			solid_move(other.x - x, other.y - y, true, other.x_vel, other.y_vel);
		}
		
		if dir == 0 || dir == 2 {
			if x == start_x {
				__collide();
			}
		}
		else {
			if y == start_y {
				__collide();
			}
		}
	}
	
});

state.change(state_idle);

