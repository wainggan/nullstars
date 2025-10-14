
if game_paused() {
	exit;
}

if instance_exists(obj_player) && obj_player.state.is(obj_player.state_cannon) && obj_player.cannon_inst == id {
	anim_holding = approach(anim_holding, 1, 0.16);
	
	if obj_player.cannon_wait {
		anim_shooting = 0;
	} else {
		anim_shooting = approach(anim_shooting, 1, 0.1);
	}
	
	anim_return = true;
	
	anim_anchor_x_vel = obj_player.x - anim_anchor_x;
	anim_anchor_y_vel = obj_player.y - anim_anchor_y;
	
	anim_anchor_accel = 0;
	
	anim_anchor_x = obj_player.x;
	anim_anchor_y = obj_player.y;
} else {
	if anim_return {
		var _dir = point_direction(anim_anchor_x, anim_anchor_y, x, y);
		
		anim_anchor_x_vel = approach(anim_anchor_x_vel, lengthdir_x(40, _dir), anim_anchor_accel);
		anim_anchor_y_vel = approach(anim_anchor_y_vel, lengthdir_y(40, _dir), anim_anchor_accel);
		
		anim_anchor_accel = approach(anim_anchor_accel, 3, 0.05);
		
		anim_anchor_x += anim_anchor_x_vel;
		anim_anchor_y += anim_anchor_y_vel;
		
		if point_distance(anim_anchor_x, anim_anchor_y, x, y) < point_distance(0, 0, anim_anchor_x_vel, anim_anchor_y_vel) { // ??
			anim_anchor_x = x;
			anim_anchor_y = y;
			anim_return = false;
		}
		
		cooldown -= 1 / 30;
	} else {
		anim_holding = approach(anim_holding, 0, 0.1);
		cooldown -= 1 / 12;
	}
	
	anim_shooting = approach(anim_shooting, 0, 0.1);
}

