
var _padding = 7;
var _anim = hermite(locked_anim);
var _door_height = _anim * 6 / 32;

if sprite_width < sprite_height {
	if locked_anim > 0 {
		draw_sprite_ext(spr_pixel, 0, x + _padding, y, sprite_width - _padding * 2, sprite_height / 2 * _anim, 0, c_white, 1);
		draw_sprite_ext(spr_pixel, 0, x + _padding, y + sprite_height, sprite_width - _padding * 2, -sprite_height / 2 * _anim, 0, c_white, 1);
		draw_line_sprite(x + 1, y, x + 1, y + sprite_height, 1, c_white, _anim);
		draw_line_sprite(x + sprite_width, y, x + sprite_width, y + sprite_height, 1, c_white, _anim);
	}
	draw_sprite_ext(spr_trapdoor, 0, x, y, image_xscale / 2, 1 + _door_height, 0, c_white, 1);
	draw_sprite_ext(spr_trapdoor, 0, x, y + sprite_height, image_xscale / 2, -(1 + _door_height), 0, c_white, 1);
} else {
	if locked_anim > 0 {
		draw_sprite_ext(spr_pixel, 0, x, y + _padding, sprite_width / 2 * _anim, sprite_height - _padding * 2, 0, c_white, 1);
		draw_sprite_ext(spr_pixel, 0, x + sprite_width, y + _padding, -sprite_width / 2 * _anim, sprite_height - _padding * 2, 0, c_white, 1);
		draw_line_sprite(x, y, x + sprite_width, y, 1, c_white, _anim);
		draw_line_sprite(x, y + sprite_height - 1, x + sprite_width, y + sprite_height - 1, 1, c_white, _anim);
	}
	draw_sprite_ext(spr_trapdoor, 0, x, y + 32, image_yscale / 2, 1 + _door_height, 90, c_white, 1);
	draw_sprite_ext(spr_trapdoor, 0, x + sprite_width, y + 32, image_yscale / 2, -(1 + _door_height), 90, c_white, 1);
}

var _key = level_get_instance(ref);
if instance_exists(_key) {
	if locked {
		draw_sprite_ext(_key.sprite_index, 1, _key.x, _key.y, 1, 1, wave(-90, 90, 12), c_white, 1);
		draw_sprite_ext(_key.sprite_index, 0, _key.x, _key.y, 1, 1, 0, c_white, 1);
	} else {
		draw_sprite_ext(_key.sprite_index, 2, _key.x, _key.y, 1, 1, 0, #bbbbbb, 1);
	}
}
