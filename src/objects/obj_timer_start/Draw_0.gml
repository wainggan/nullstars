
var _evil_dir := (anim_dir + 2) % 4;

if _evil_dir != 0 {
	draw_sprite_ext(
		spr_timer_start, 0,
		x, y,
		image_xscale, image_yscale,
		0, c_white, 1
	);
}
if _evil_dir != 1 {
	draw_sprite_ext(
		spr_timer_start, 1,
		x, y,
		image_xscale, image_yscale,
		0, c_white, 1
	);
}
if _evil_dir != 2 {
	draw_sprite_ext(
		spr_timer_start, 2,
		x, y,
		image_xscale, image_yscale,
		0, c_white, 1
	);
}
if _evil_dir != 3 {
	draw_sprite_ext(
		spr_timer_start, 3,
		x, y,
		image_xscale, image_yscale,
		0, c_white, 1
	);
}

draw_sprite_ext(
	spr_timer_start, 4,
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

