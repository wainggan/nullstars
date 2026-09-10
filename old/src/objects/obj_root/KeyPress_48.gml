
mode_slow = !mode_slow;
if mode_slow {
	LOG(Log.user, "set to 10fps");
	game_set_speed(10, gamespeed_fps);
} else {
	LOG(Log.note, "set to 60fps");
	game_set_speed(60, gamespeed_fps);
}

