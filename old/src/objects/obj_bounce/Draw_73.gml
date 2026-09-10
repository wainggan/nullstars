
var _x_scale = round_ext(1 - anim_bounce * 0.8, 0.05);
var _y_scale = round_ext(1 + anim_bounce * 0.8, 0.05);

draw_sprite_ext(sprite_index, 0, x, y, _x_scale, _y_scale, 0, c_white, 1);

