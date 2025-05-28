
//draw_text(16, 16 + 12 * 0, instance_number(obj_Exists));
//draw_text(16, 16 + 12 * 1, fps);

if keyboard_check_pressed(ord("9")) {
	// @todo: windows?
	var _where = $"{game_save_id}\\{string(irandom(999999999))}.png";
	screen_save(_where);
	LOG(Log.user, $"screenshot saved: {_where}");
}

