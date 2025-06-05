
draw_sprite_ext(
	spr_debug_timer_start, global.time / 20,
	x, y,
	image_xscale, image_yscale,
	0, c_white, 1
);

with level_get_instance(ref) {
	draw_sprite_ext(
		spr_debug_timer_start, global.time / 20,
		x, y,
		image_xscale, image_yscale,
		0, c_white, 1
	);
}

