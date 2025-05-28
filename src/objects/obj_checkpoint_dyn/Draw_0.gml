
var _color = #eebbff;
var _y = y + wave(-2, 2, 14);

light.color = _color;
light.intensity = 0.5;
light.size = 48;
light.x = x;
light.y = _y;

draw_sprite_ext(
	sprite_index, 0,
	x, _y,
	1, 1, 0, _color, 1
);
