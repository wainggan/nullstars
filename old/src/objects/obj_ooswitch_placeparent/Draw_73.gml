
var _scale = 1 + anim_hit * 0.75;
//var _color = merge_color(c_white, c_gray, max(0, hit_buffer / global.defs.oo_place_delay));
draw_sprite_ext(sprite_index, 0, x, y, _scale, _scale, 0, c_white, 1);

// todo: this looks ugly
if hit_buffer > 0 {
	draw_circle_sprite_outline(x, y, 24 - 12 * tween(Tween.Cubic, 1 - hit_buffer / global.defs.oo_place_delay), 1, c_white, 1, 15);
}
if -3 <= hit_buffer && hit_buffer <= 0 {
	draw_circle_sprite(x, y, 30, c_white, 1);
}
