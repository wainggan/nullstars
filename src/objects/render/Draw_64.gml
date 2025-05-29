
var _cam = game_camera_get();


if anim_time > 0 {
	
	var _pos_x = WIDTH / 2,
		_pos_y = 40;
	
	// terp(1, 0, Tween.Quart, anim_time) * 80
	
	surface_set_target(surf_ping);
	draw_clear_alpha(c_black, 0);
	
	draw_sprite_ext(spr_timer_background, 0, _pos_x, _pos_y + 16, 32, 1.5, 0, #000000, 1);
	draw_sprite_ext(spr_timer_background, 0, _pos_x, _pos_y + 16, 10, 3, 0, #000000, 1);
	
	
	gpu_set_colorwriteenable(true, true, true, false);
	
	draw_sprite_stretched_ext(spr_timer_background, 0, _pos_x - 256 - 16, _pos_y + 8 - 1, 256 - 16, 16, #444455, 1);
	draw_sprite_stretched_ext(spr_timer_background, 0, _pos_x + 32, _pos_y + 8 - 1, 256, 16, #444455, 1);
	draw_sprite_tiled_area_ext(spr_timer_water, 0, wave(-24, 24, 11), _pos_y, _pos_x - 256, _pos_y, _pos_x + 256, _pos_y + 48, #111126, 1);
	
	
	gpu_set_colorwriteenable(true, true, true, true);
	
	surface_reset_target();
	
	draw_surface(surf_ping, 0, 0);
	
	shader_set(shd_outline)
	var _u_texel = shader_get_uniform(shd_outline, "u_texel");
	shader_set_uniform_f(_u_texel, 1 / WIDTH, 1 / HEIGHT);
	draw_surface_ext(surf_ping, 0, 0, 1, 1, 0, #ffffff, 1);
	shader_reset();
	
	draw_set_halign(fa_center);
	draw_set_font(ft_timer);
	
	draw_text_ext_transformed(_pos_x, _pos_y - 2, cache_time_str, -1, -1, 2, 2, 0);
	
	draw_set_halign(fa_left);
	
	
}


// holy shit please fucking kill me
// ??????????
var _x = 0;
var _y = 0;
if instance_exists(obj_player) {
	_x = obj_player.x + 16;
	_y = obj_player.y - 100;
}
for (var i = 0; i < array_length(global.game.menu.system.stack); i++) {
	// I feel like I had my entire bloodline implicitly cursed after writing this
	//if i < array_length(obj_menu.system.stack) {
	global.game.menu.system.stack[i].draw(_x - _cam.x, _y - _cam.y, 1);
	//}
	//else if obj_menu.cache[i] != undefined {
		//obj_menu.cache[i].draw(_x - _cam_x, _y - _cam_y, obj_menu.anims[i]);
	//}
	_x += 24;
}


var _x = 20,
	_y = _cam.h - 16;

draw_set_font(ft_sign);
draw_set_color(c_white);

for (var i = array_length(global.logger.messages) - 1; i >= 0; i--) {
	draw_text_ext_transformed(
		_x, _y, 
		global.logger.messages[i], 
		-1, -1, 
		1, 1, 
		0
	);
	_y -= 16;
}
