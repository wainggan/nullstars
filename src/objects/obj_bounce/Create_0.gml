/*
 * trampoline object
 * 
 * defines a "bounce" event, as follows:
 *     function (_dir, _from_x, _from_y);
 * `_dir` defines what direction the spring is bouncing to. 0 is up
 * `_from_x` defines where the object should be snapped to. if _dir == 0, this is meaningless.
 * `_from_y` defines where the object should be snapped to. if _dir != 0, this is meaningless.
*/

event_inherited()

x += 16;
y += 32;

glue_child_setup();
glue_child_set_move(function (_x, _y) {
	x = _x;
	y = _y;
});

cache_actors = ds_list_create();

anim_bounce = 0;
anim_vel = 0;

