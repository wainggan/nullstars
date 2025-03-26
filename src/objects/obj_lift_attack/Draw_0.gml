
var _cam = game_camera_get();

if state.is(state_idle) {
	// todo:
	draw_sprite_tiled_area(
		spr_spike_pond_fill, 0,
		wave(-32, 32, 12), wave(-24, 24, 10, 0.5),
		min(x, anim_sight_x) + 8, min(y, anim_sight_y) - 8,
		max(x + sprite_width, anim_sight_x) - 8, max(y + sprite_height, anim_sight_y) - 8
	);
}

