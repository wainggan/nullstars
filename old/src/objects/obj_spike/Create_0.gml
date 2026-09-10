
event_inherited();

parent = noone;

x_off = 0;
y_off = 0;

// used by the player for collision
x_delta = 0;
y_delta = 0;

glue_child_setup();
glue_child_set_move(function (_x, _y) {
	x_delta = _x - x;
	y_delta = _y - y;
	x = _x;
	y = _y;
});

