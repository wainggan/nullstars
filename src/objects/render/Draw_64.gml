
var _cam = game_camera_get();


if anim_time_main > 0 {
	var _pos_x = WIDTH / 2,
		_pos_y = 0;
	
	// terp(1, 0, Tween.Quart, anim_time) * 80
	
	var _anim0 = tween(Tween.Quart, anim_time_main);
	var _anim1 = tween(Tween.Quart, clamp(2 * (anim_time_main - 0.5), 0, 1));
	var _anim2 = tween(Tween.Back, anim_time_main);
	var _animc = hermite(anim_time_close);
	
	var _colo = merge_color(#ffffff, #000000, _animc);
	
	surface_set_target(surf_ping);
	draw_clear_alpha(c_black, 0);
	
	// long bar
	draw_sprite_ext(spr_timer_background, 0, WIDTH / 2, 0, 32 * _anim0, 3, 0, #000000, 1);
	// main background
	draw_sprite_ext(spr_timer_background, 0, WIDTH / 2, 0, 12 * _anim0, 6 * _anim2, 0, #000000, 1);
	
	
	gpu_set_colorwriteenable(true, true, true, false);
	
	var _com = 0;
	if game_timer_running() {
		_com = global.game.state.timer_current / global.game.state.timer_length;
	} else {
		_com = 1;
	}
	
	// bar timer
	//gpu_set_blendmode(bm_add);
	var _colb = merge_color(#44444f, #000000, _animc);
	draw_sprite_stretched_ext(spr_timer_background, 0, _pos_x - 256 - 16, _pos_y + 8 - 2, (256 + 16) * _com, 16, _colb, 1);
	draw_sprite_stretched_ext(spr_timer_background, 0, _pos_x + (256 + 16) * (1 - _com), _pos_y + 8 - 2, 256 + 16, 16, _colb, 1);
	//gpu_set_blendmode(bm_normal);
	
	gpu_set_texfilter(true);
	gpu_set_blendmode(bm_max);
	draw_sprite_tiled_ext(spr_atmosphere_clouds, 0, 0, global.time / 4, 8, 8, #444444, 1);
	gpu_set_blendmode(bm_normal);
	gpu_set_texfilter(false);
	
	// time close cover up
	draw_sprite_ext(spr_timer_background, 0, _pos_x, _pos_y + 16, 32 * _animc, 6, 0, #ffffff, 1);
	
	// waves
	var _colw = merge_color(#000000, #eeeef0, _animc);
	draw_sprite_tiled_area_ext(spr_timer_water, 0, wave(-24, 24, 11), _pos_y, _pos_x - 256, _pos_y, _pos_x + 256, _pos_y + 48, _colw, 1);
	
	draw_set_halign(fa_center);
	draw_set_font(ft_timer);
	
	// text
	var _colt = merge_color(#ffffff, #000000, _animc);
	draw_text_ext_transformed_color(_pos_x, _pos_y + 5 - (1 - _anim2) * 16, cache_time_str, -1, -1, 2, 2, 0, _colt, _colt, _colt, _colt, 1);
	draw_text_ext_transformed_color(_pos_x + 128, _pos_y + 4 - (1 - _anim1) * 24, cache_elapse_str, -1, -1, 0.8, 0.8, 0, _colt, _colt, _colt, _colt, 1);
	
	draw_set_halign(fa_left);
	
	gpu_set_colorwriteenable(true, true, true, true);
	
	surface_reset_target();
	
	// outline
	// long bar
	draw_sprite_ext(spr_timer_background, 0, WIDTH / 2, 2, 32 * _anim0, 3, 0, _colo, 1);
	// main background
	draw_sprite_ext(spr_timer_background, 0, WIDTH / 2, 2, 12 * _anim0, 6 * _anim2, 0, _colo, 1);
	
	draw_surface(surf_ping, 0, 0);
	
	//shader_set(shd_outline)
	//var _u_texel = shader_get_uniform(shd_outline, "u_texel");
	//shader_set_uniform_f(_u_texel, 1 / WIDTH, 1 / HEIGHT);
	//var _colo = merge_color(#ffffff, #000000, _animc);
	//draw_surface_ext(surf_ping, 0, 0, 1, 1, 0, _colo, 1);
	//shader_reset();
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

for (var i = 0; i < array_length(global.logger.messages); i++) {
	draw_text_ext_transformed(
		_x, _y, 
		global.logger.messages[i], 
		-1, -1, 
		1, 1, 
		0
	);
	_y -= 16;
}
