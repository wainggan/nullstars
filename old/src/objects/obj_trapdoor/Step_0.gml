
if game_paused() {
	exit;
}

var _key = level_get_instance(ref);
with _key {
	if other.locked && place_meeting(x, y, obj_player) {
		other.locked = false;
		game_set_pause(5);
	}
	if other.locked {
		other.pet.collidable = true;
	} else {
		other.pet.collidable = false;
	}
}

locked_anim = approach(locked_anim, +locked, 0.1);

