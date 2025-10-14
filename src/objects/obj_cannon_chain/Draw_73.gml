
var _main_radius = 12;
var _main_thick = 24;

var _anchor_radius = 0;

_main_radius = herp(_main_radius, 20, anim_holding);
_main_thick = herp(_main_thick, 4, anim_holding);
_anchor_radius = herp(_anchor_radius, 40 - (1 - anim_shooting) * 10, power(anim_holding, 2));

_main_radius = herp(_main_radius, 16, anim_shooting);
_main_thick = herp(_main_thick, 6, anim_shooting);

draw_circle_sprite(anim_anchor_x, anim_anchor_y, _anchor_radius, c_white, 1);
draw_sprite_ext(spr_cannon_chain, 1, anim_anchor_x, anim_anchor_y, anim_shooting, anim_shooting, 0, c_white, 1);

for (var i = 0; i < 6; i += 1) {
	var _off_dir = i % 2 == 0 ? 1 : -1.01;
	var _off_x = lengthdir_x(_main_radius + _main_thick / 2, 360 / 6 * i + global.time * _off_dir);
	var _off_y = lengthdir_y(_main_radius + _main_thick / 2, 360 / 6 * i + global.time * _off_dir);
	draw_circle_sprite(x + _off_x, y + _off_y, 12 * anim_holding, c_white, 1);
}

draw_circle_outline(x, y, _main_radius, _main_thick, c_white, 1);

