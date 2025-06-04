
image_yscale = jorp_h;

event_inherited();

glue_child_setup();
glue_child_set_move(function(_x, _y) {
	var _xv = _x - x;
	
	pos += -_xv / scale / 2;
	
	x = _x;
	y = _y;
})

pos = 0;
vel = 0;

// good enough
scale = clamp(140 / sqrt(sprite_height), 2, 16);

hit = 0;


light = instance_create_layer(x, y, "Lights", obj_light, {
	intensity: intensity,
	color: color,
	size: size,
});

reset = function() {
	vel = 0;
	x = xstart;
	y = ystart;
};

