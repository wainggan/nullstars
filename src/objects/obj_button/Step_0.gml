
var _touching = instance_place(x, y, obj_Actor);

if _touching != noone && !touching {
	if _touching.object_index == obj_player {
		game_set_pause(4);
	}
	trigger_run();
	trigger_send();
}

touching = _touching != noone;

