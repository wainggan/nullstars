
image_xscale = jorp_w;
image_yscale = jorp_h;

event_inherited();

trigger_setup();
glue_parent_setup();

pet = instance_create_layer(x, y, layer, obj_Solid, {
	image_xscale: sprite_width, image_yscale: sprite_height,
});
pet.outside = exists_outside_empty();

riding = function(){
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
		dir = 90;
		break;
	case "left":
		dir = 180;
		break;
	case "down":
		dir = 270;
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

rest = true;

anim_vel = 0;
anim_sight_x = x; // @todo: bandage
anim_sight_y = y;
anim_frame = 0;
anim_line = 1;

trigger_set(function(){
	if !rest return;
	state.change(state_active)
});

reset = function(){
	state.change(state_idle);
	x = xstart;
	y = ystart;
	glue_parent_moved(x, y);
	reset_polarity_x = 0;
	reset_polarity_y = 0;
	rest = true;
	with pet {
		x = other.x;
		y = other.y;
	}
};


state = new State();

state_idle = state.add()
.set("enter", function() {
	time = 10;
})
.set("step", function(){
	
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
	
})

state_active = state.add()
.set("enter", function(){
	x_vel = 0;
	y_vel = 0;
	accel = 0;
	
	start_x = x;
	start_y = y;
	
	anim_line = 1;
	
	reset_polarity_x = lengthdir_x(1, dir);
	reset_polarity_y = lengthdir_y(1, dir);
	
	rest = false;
	
	instance_create_layer(x, y, layer, obj_effects_rectpop, {
		width: sprite_width,
		height: sprite_height,
		pad: 16,
		spd: 0.04,
	});
})
.set("step", function(){
	
	accel += 0.05;
	x_vel = approach(x_vel, lengthdir_x(spd, dir), accel);
	y_vel = approach(y_vel, lengthdir_y(spd, dir), accel);
	
	anim_vel += min(point_distance(0, 0, x_vel, y_vel), 5);
	anim_frame += 2;
	
	pet.mask_index = spr_none;
	mask_index = sprite_index;
	
	actor_move_x(x_vel, function(){
		game_camera_set_shake(4, 0.4)
		state.change(state_retract);
	});
	actor_move_y(y_vel, function(){
		game_camera_set_shake(4, 0.4)
		state.change(state_retract);
	});
	glue_parent_moved(x, y);
	
	pet.mask_index = pet.sprite_index;
	mask_index = spr_none;
	
	with pet solid_move(other.x - x, other.y - y, , other.x_vel, other.y_vel);
	
})

state_retract = state.add()
.set("enter", function(){
	x_vel = 0;
	y_vel = 0;
	accel = 0;
	time = 10;
})
.set("leave", function(){
	rest = true;
})
.set("step", function(){
	
	var _dir = dir + 180;
	
	time -= 1;
	if time < 0 {
		accel = approach(accel, 0.04, 0.002);
		x_vel = approach(x_vel, lengthdir_x(global.defs.lift_spd_return, _dir), accel);
		y_vel = approach(y_vel, lengthdir_y(global.defs.lift_spd_return, _dir), accel);
		
		anim_vel -= point_distance(0, 0, x_vel, y_vel);
		anim_frame += 1;
		
		pet.mask_index = spr_none;
		mask_index = sprite_index;
		
		actor_move_x(x_vel, function(){
			game_camera_set_shake(2, 0.4);
			state.change(state_idle);
		});
		actor_move_y(y_vel, function(){
			game_camera_set_shake(2, 0.4);
			state.change(state_idle);
		});
		glue_parent_moved(x, y);
		
		pet.mask_index = pet.sprite_index;
		mask_index = spr_none;
		
		with pet solid_move(other.x - x, other.y - y, , other.x_vel, other.y_vel);
	}
	
	if (sign(x - start_x) != reset_polarity_x)
	|| (sign(y - start_y) != reset_polarity_y) {
		
		pet.mask_index = spr_none;
		mask_index = sprite_index;
		
		game_camera_set_shake(2, 0.4)
		
		actor_move_x(start_x - x);
		actor_move_y(start_y - y);
		glue_parent_moved(x, y);
		
		pet.mask_index = pet.sprite_index;
		mask_index = spr_none;
		
		with pet solid_move(other.x - x, other.y - y, , 0, 0);
		
		state.change(state_idle)
	}
	
})


state.change(state_idle)

