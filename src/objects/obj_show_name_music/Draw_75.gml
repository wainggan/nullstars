
var _pos_x = WIDTH - 20,
	_pos_y = HEIGHT - 30 * hermite(anim)

draw_set_halign(fa_right);
draw_set_font(ft_timer);

draw_text_transformed(_pos_x, _pos_y, $"playing: {name}", 1, 1, 0);

draw_set_halign(fa_left);

