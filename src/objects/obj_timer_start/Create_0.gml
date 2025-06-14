
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

