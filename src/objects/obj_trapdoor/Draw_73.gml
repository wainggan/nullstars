
draw_sprite_ext(spr_pixel, 0, x + 7, y, 18, sprite_height / 2 * locked_anim, 0, c_white, 1);
draw_sprite_ext(spr_pixel, 0, x + 7, y + sprite_height, 18, -sprite_height / 2 * locked_anim, 0, c_white, 1);

draw_sprite_ext(spr_trapdoor, 0, x, y, 1, 1 + locked_anim * 6 / 32, 0, c_white, 1);
draw_sprite_ext(spr_trapdoor, 0, x, y + sprite_height, 1, -(1 + locked_anim * 6 / 32), 0, c_white, 1);

var _key = level_get_instance(ref);
if instance_exists(_key) {
	if locked {
		draw_sprite_ext(_key.sprite_index, 1, _key.x, _key.y, 1, 1, wave(-90, 90, 12), c_white, 1);
		draw_sprite_ext(_key.sprite_index, 0, _key.x, _key.y, 1, 1, 0, c_white, 1);
	} else {
		draw_sprite_ext(_key.sprite_index, 2, _key.x, _key.y, 1, 1, 0, #bbbbbb, 1);
	}
}
