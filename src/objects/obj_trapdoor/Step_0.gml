
if game_paused() {
	exit;
}

var _key = level_get_instance(ref);
ASSERT(instance_exists(_key));
with _key {
	if place_meeting(x, y, obj_player) {
		other.locked = false;
	}
	if other.locked {
		collidable = true;
	} else {
		collidable = false;
	}
}

locked_anim = approach(locked_anim, +locked, 0.1);

