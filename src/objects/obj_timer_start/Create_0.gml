
event_inherited();

image_xscale = jorp_w;
image_yscale = jorp_h;

last_check = false;
last_able = false;
last_alive = false;

last_x = 0;
last_y = 0;

// global.game.gate.add(self);

pet = noone;

anim_wall = 0;
anim_running = 0;
anim_is_complete = false;
anim_complete = 0;
anim_pop = false;
anim_menu = 0;

anim_dir = 0;
if dir == "right" {
	dir = "right";
	anim_dir = 0;
} else if dir == "left" {
	dir = "left";
	anim_dir = 2;
} else if dir == "down" {
	dir = "down";
	anim_dir = 3;
} else if dir == "up" {
	dir = "up";
	anim_dir = 1;
} else {
	ASSERT(false);
}

var _off_left = dir == "left" ? 32 : 128;
var _off_right = dir == "right" ? 32 : 128;
var _off_top = dir == "up" ? 32 : 128;
var _off_bottom = dir == "down" ? 32 : 128;

pet_menu := instance_create_layer(x, y, "Instances", obj_flag_menu);
with pet_menu {
	x = other.bbox_left - _off_left;
	y = other.bbox_top - _off_top;
	image_xscale = (other.bbox_right + _off_right) - x;
	image_yscale = (other.bbox_bottom + _off_bottom) - y;
	
	target = global.game.menu.page_gate_none;
	
	at_x = other.x + (other.bbox_right - other.bbox_left) / 2;
	at_y = other.bbox_bottom + 8;
	priority = 0;
}


