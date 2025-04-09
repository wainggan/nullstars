
var _accel = 0.005 * -pos;

vel *= 0.975;
vel += _accel;

pos += vel;
if abs(pos) > 1 && sign(vel) == sign(pos) {
	vel *= 0.94;
}

var _b_x = x + lengthdir_x(sprite_height, -90 + pos * scale);
var _b_y = y + lengthdir_y(sprite_height, -90 + pos * scale);

if collision_line(x, y, _b_x + 8, _b_y, obj_player, false, false) != noone {
	if hit <= 0 {
		if abs(vel) < abs(obj_player.x_vel) {
			vel = clamp(obj_player.x_vel * 0.02, -1, 1);
		}
	}
	hit = 8;
} else {
	hit -= 1;
}


light.x = _b_x + 8;
light.y = _b_y - 8;

