
anim_dive_timer -= 1;
anim_jab_timer -= 1;
anim_longjump_timer -= 1;
anim_flip_timer -= 1;
anim_runjump_timer -= 1;

if !game_paused() {
	if state.is(state_cannon) {
		x_anim = lerp(x_anim, x, 0.1);
		y_anim = lerp(y_anim, y, 0.1);
		x_scale_anim = lerp(x_scale_anim, 0, 0.2);
		y_scale_anim = lerp(y_scale_anim, 0, 0.2);
	} else {
		x_anim = x;
		y_anim = y;
		x_scale_anim = lerp(x_scale_anim, 1, 0.2);
		y_scale_anim = lerp(y_scale_anim, 1, 0.2);
	}
}

var _sprite = spr_player;
var _pos_x = x_anim;
var _pos_y = y_anim;
var _angle = 0;
var _dir = dir;
var _visible = true;
var _scale_x = x_scale_anim;
var _scale_y = y_scale_anim;

if state.is(state_swim_bullet) {
	anim.set("swimbullet");
	_angle = swim_dir;
	_dir = 1;
	_pos_y -= 16;
}
else if state.is(state_swim) {
	
	var _swim_spd = point_distance(0, 0, x_vel, y_vel);
	var _swim_dir = point_direction(0, 0, x_vel, y_vel);
	
	if _swim_spd < 1 {
		anim.extract("swim").speed = 1 / 60;
		anim.set("swim");
	}
	else if abs(_swim_dir % 360 - 90) < 10 || (abs(_swim_dir % 360 - 270) < 10 && false) {
		anim.extract("swim").speed = 1 / round(max(20 - abs(_swim_spd) * 2, 8));
		anim.set("swim");
	}
	else {
		anim.extract("swimming").speed = 1 / round(max(20 - abs(_swim_spd) * 2, 8));
		anim.set("swimming");
	}
	
	_pos_y += wave(-2, 3, 8);
	
}
else if state.is(state_ledge) {
	anim.set("ledge");
}
else if state.is(state_menu) {
	anim.set("idle");
}
else if state.is(state_dash) || anim_dive_timer || anim_jab_timer {
	if anim_dive_timer > 0 {
		anim.set("dive");
	} else {
		anim.set("jab");
	}
}
else if state.is(state_free) {
	if nat_crouch() && anim_longjump_timer <= 0 {
		anim.set("crouch");
	}
	else if actor_collision(x, y + 1) && y_vel >= 0 {
		if abs(x_vel) < 0.8 {
			anim.set("idle");
		}
		else if abs(x_vel) > defs.move_speed + 2 {
			anim.extract("run").speed = 1 / 3;
			anim.set("run");
		}
		else {
			anim.extract("walk").speed = 1 / round(max(12 - abs(x_vel) * 2, 6));
			anim.set("walk");
		}
	}
	else if anim_longjump_timer > 0 {
		anim.set("longjump");
	}
	else if anim_flip_timer > 0 && y_vel < 0 {
		anim.set("flip");
	}
	else {
		if y_vel < 0 {
			if anim_runjump_timer > 0 {
				anim.set("runjump");
			} else {
				anim.set("jump");
			}
		}
		else {
			if anim_runjump_timer > 0 {
				anim.set("runfall");
			} else {
				anim.set("fall");
			}
		}
	}
}
else if state.is(state_cannon) {
}

anim.update();

var _meta = anim.meta();

if !game_paused() {
	tail.update(
		_pos_x + (_meta.x ?? 0) * _dir * _scale_x,
		_pos_y + (_meta.y ?? 0) * _scale_y,
		dir,
		state.is(state_swim_bullet) ? 1 : 0,
		global.data.player.tail
	);
}

if _visible {
	if !(_meta.front ?? true) {
		tail.draw(dash_left, global.data.player.tail, global.data.player.color, c_white, _scale_x);
	}
	
	var _frame = anim.get();
	
	draw_player(_frame, _pos_x, _pos_y, scale_x * _dir * _scale_x, scale_y * _scale_y, _angle, c_white, global.data.player.cloth, global.data.player.accessory, global.data.player.ears, global.data.player.color);
	
	if _meta.front ?? true {
		tail.draw(dash_left, global.data.player.tail, global.data.player.color, c_white, _scale_x);
	}
}
