
var _cam_x = camera_get_view_x(view_camera[0]),
	_cam_y = camera_get_view_y(view_camera[0]),
	_cam_w = camera_get_view_width(view_camera[0]),
	_cam_h = camera_get_view_height(view_camera[0]);


var _lvl_onscreen = game_level_onscreen();


// clear screen
draw_clear_alpha(c_black, 0);


// -- background --

if !surface_exists(surf_background)
	surf_background = surface_create(_cam_w, _cam_h);

// only draw a backround if there is one on screen
if array_length(_lvl_onscreen) > 0 {
	
	var _first = game_level_grab_data(_lvl_onscreen[0]).background;
	
	// mask layer
	surface_set_target(surf_ping);
	draw_clear_alpha(c_black, 0);
	
	// only two backgrounds can be drawn in one frame
	var _second = undefined;
	with obj_room_portal {
		_second = background;
		draw_sprite_ext(
			spr_pixel, 0,
			x - _cam_x, y - _cam_y,
			sprite_width, sprite_height,
			0, c_white, 1,
		);
	}
	
	for (var i = 0; i < array_length(_lvl_onscreen); i++) {
		var _lvl = _lvl_onscreen[i];
		var _this = game_level_grab_data(_lvl).background;
		
		if _this != _first {
			
			// thanks feather ???
			_second ??= _this;
			
			// mask
			draw_sprite_ext(
				spr_pixel, 0,
				_lvl.x - _cam_x, _lvl.y - _cam_y,
				_lvl.width, _lvl.height,
				0, c_white, 1,
			);
			
		}
	
	}
	
	// draw second background onto mask
	gpu_set_colorwriteenable(1, 1, 1, 0);
	if _second != undefined {
		game_background_get(_second).draw(); // bad idea
	}
	gpu_set_colorwriteenable(1, 1, 1, 1);
	
	surface_reset_target();
	
	// put everything together
	surface_set_target(surf_background);
	draw_clear_alpha(c_black, 1);

	game_background_get(_first).draw(); // still a bad idea
	draw_surface(surf_ping, 0, 0);

	surface_reset_target();
	
}

if config.background_timer && (anim_time > 0 || anim_time_main > 0) {
	surface_set_target(surf_ping);
	draw_clear_alpha(c_black, 0);
	
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ft_timer);
	
	var _anim0 = hermite(anim_time);
	var _anim1 = hermite(clamp(2 * (anim_time - 0.5), 0, 1));
	var _anim2 = hermite(clamp(2 * (anim_time), 0, 1));
	
	var _col = 0;
	
	_col = #222222;
	var _inc = 256;
	for (var _y = -_inc + global.time % _inc; _y < HEIGHT + _inc; _y += _inc) {
		draw_text_ext_transformed_color(WIDTH / 2, _y, cache_time_str, -1, -1, 10, 10, 0, _col, _col, _col, _col, _anim1);
	}
	
	_col = #aaaaaa;
	draw_sprite_ext(spr_pixel, 0, 0, HEIGHT / 2 - 120 - 10 - 10 * _anim2, WIDTH, 20 * _anim2, 0, _col, 1);
	draw_sprite_ext(spr_pixel, 0, 0, HEIGHT / 2 + 120 + 10 * (1 - _anim2), WIDTH, 20 * _anim2, 0, _col, 1);
	
	_inc = 48;
	var _off = global.time div _inc;
	
	for (var _x = -_inc, i = 0; _x < WIDTH + _inc; {
		_x += _inc;
		i++;
	}) {
		var _rad0 = round_ext(wave(6, 18, 12, (i - _off) / (pi * 2)), 2);
		var _rad1 = round_ext(wave(6, 18, 12, (i + _off) / (pi * 2)), 2);
		draw_circle_sprite(_x + global.time % _inc, HEIGHT / 2 - 120 - 10, _rad0, c_black, 1);
		draw_circle_sprite(_x + -global.time % _inc, HEIGHT / 2 + 120 + 10, _rad1, c_black, 1);
	}
	
	_col = #bbbbbb;
	draw_text_ext_transformed_color(WIDTH / 2, HEIGHT / 2, cache_time_str, -1, -1, 6, 6, 0, _col, _col, _col, _col, _anim0);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	
	if anim_target_w != 0 {
		var _sint = 200;
		var _san0 = 1 - tween(Tween.Cubic, global.time % _sint / _sint);
		var _san1 = 1 - tween(Tween.Cubic, (global.time + (_sint / 2)) % _sint / _sint);
		var _cent_x = anim_target_x + anim_target_w / 2 - _cam_x;
		var _cent_y = anim_target_y + anim_target_h / 2 - _cam_y;
		draw_sprite_ext(
			spr_timer_wave, 0,
			_cent_x,
			_cent_y,
			_san0 * (96 + anim_target_w / 16),
			_san0 * (96 + anim_target_h / 16),
			0, c_white, max(0, 0.6 - 0.6 * power(_san0, 2)) * (1 - anim_time_close)
		);
		draw_sprite_ext(
			spr_timer_wave, 0,
			_cent_x,
			_cent_y,
			_san1 * (96 + anim_target_w / 16),
			_san1 * (96 + anim_target_h / 16),
			0, c_white, max(0, 0.6 - 0.6 * power(_san1, 2)) * (1 - anim_time_close)
		);
	}
	
	surface_reset_target();
	
	surface_set_target(surf_background);
	
	game_render_refresh();
	game_render_blendmode_set(shd_blend_colordodge);
	draw_surface(surf_ping, 0, 0);
	game_render_blendmode_reset();
	
	var _anim3 = hermite(min(1 - anim_time_close, anim_time_main));
	var _hei = 54;
	_col = #78777a;
	
	gpu_set_blendmode_ext(bm_dest_color, bm_zero);
	draw_sprite_ext(spr_pixel, 0, 0, 0, WIDTH, _hei * _anim3, 0, _col, 1);
	draw_sprite_ext(spr_pixel, 0, 0, HEIGHT - _hei * _anim3, WIDTH, _hei, 0, _col, 1);
	gpu_set_blendmode(bm_normal);
	
	surface_reset_target();
}



// -- set up background lights --

if !surface_exists(surf_background_lights)
	surf_background_lights = surface_create(_cam_w, _cam_h);

// clear lights
surface_set_target(surf_background_lights);
draw_clear(c_black);

shader_set(shd_rimlight);
draw_surface(surf_background, 0, 0);
shader_reset();

surface_reset_target();


// -- bubbles --

if !surface_exists(surf_bubbles)
	surf_bubbles = surface_create(_cam_w, _cam_h);

// bubble surface for masking
surface_set_target(surf_bubbles);
draw_clear_alpha(c_black, 0)

// draw bubble base
with obj_spike_bubble {
	var _size = 1
	if global.config.graphics_up_bubble_wobble
		_size = round_ext(wave(0.95, 1.1, 8, offset), 0.05)
	
	draw_sprite_ext(spr_spike_bubble, 0, x - _cam_x, y - _cam_y, _size, _size, 0, c_black, 1);
	draw_sprite_ext(spr_spike_bubble, 1, x - _cam_x, y - _cam_y, size, size, offset % 360, c_black, 1);
}

with obj_spike_pond {
	var _size = 2, _frame = floor(global.time / 60);
	if global.config.graphics_up_bubble_wobble {
		_size = round_ext(wave(0, 4, 9, offset), 1);
		_frame = floor(wave(0, 24, 10, offset));
	}
	
	draw_sprite_ext(spr_spike_pond, 0, x - _cam_x, y - _cam_y, image_xscale, image_yscale, 0, c_black, 1);
	draw_sprite_stretched_ext(
		spr_spike_pond_waves, _frame,
		x - (16 - _size) - _cam_x, y - (16 - _size) - _cam_y,
		sprite_width + (16 - _size) * 2, sprite_height + (16 - _size) * 2,
		c_black, 1
	);
}

// disable alpha to use the base as a mask
gpu_set_colorwriteenable(true, true, true, false)

// var _col = merge_color(#49f273, #aa78fa, power(sin(global.time / 60) * 0.5 + 0.5, 6))
var _col = #49f273;

draw_sprite_tiled_ext(spr_spike_stars, 0, floor(- _cam_x / 2), floor(- _cam_y / 2), 2, 2, merge_color(c_white, _col, 1), 1)
draw_sprite_tiled_ext(spr_spike_stars, 0, floor(- _cam_x / 4), floor(- _cam_y / 4), 2, 2, merge_color(c_white, _col, 0.5), 1)
draw_sprite_tiled_ext(spr_spike_stars, 0, floor(- _cam_x / 8), floor(- _cam_y / 8), 2, 2, merge_color(c_white, _col, 0.25), 1)

if global.config.graphics_up_bubble_spike {

	// draw the Xs
	with obj_spike_bubble {
		var _size = 1;
		var _off_x = 0;
		var _off_y = 0;
		if global.config.graphics_up_bubble_wobble {
			_size = round_ext(wave(0.8, 2, 18, offset + 1000), 0.05);
			_off_x = round_ext(wave(-6, 6, 23, offset * 2), 1);
			_off_y = round_ext(wave(-6, 6, 24, offset * 3), 1);
		}
	
		draw_sprite_ext(spr_spike_x, 0, x + _off_x - _cam_x, y + _off_y - _cam_y, _size, _size, 0, _col, 1);
	}

	var _scissor = gpu_get_scissor();
	with obj_spike_pond {
		var _off_0 = 0;
		var _off_1 = 0;
		if global.config.graphics_up_bubble_wobble {
			_off_0 = round_ext(wave(-96, 96, 30, offset * 2), 1);
			_off_1 = round_ext(wave(-128, 128, 36, offset * 3), 1);
		}
		gpu_set_scissor(x - _cam_x + 2, y - _cam_y + 2, sprite_width - 4, sprite_height - 4);
		draw_sprite_tiled_ext(spr_spike_pond_fill, 0, -_cam_x * 0.9, _off_0 - _cam_y * 0.9, 1, 1, _col, 1);
		draw_sprite_tiled_ext(spr_spike_pond_fill, 1, -_cam_x * 0.9, _off_1 - _cam_y * 0.9, 1.5, 1.5, _col, 1);
	}
	gpu_set_scissor(_scissor);

}

gpu_set_colorwriteenable(true, true, true, true)

surface_reset_target()

// begin bubble outline
gpu_set_blendmode_ext(bm_one, bm_zero)

surface_set_target(surf_ping)

if global.config.graphics_up_bubble_outline {

	shader_set(shd_outline);
	var _u_texel = shader_get_uniform(shd_outline, "u_texel");
	shader_set_uniform_f(_u_texel, 1 / _cam_w, 1 / _cam_h);
		draw_surface_ext(surf_bubbles, 0, 0, 1, 1, 0, _col, 1);
	shader_reset();

} else {
	
	draw_surface_ext(surf_bubbles, 0, 0, 1, 1, 0, _col, 1);
	
}

surface_reset_target()
surface_set_target(surf_bubbles)

draw_surface(surf_ping, 0, 0);

surface_reset_target()
gpu_set_blendmode(bm_normal)


surface_set_target(surf_layer_0);
draw_clear_alpha(c_black, 0);

// draw level backgrounds
for (var i = 0; i < array_length(_lvl_onscreen); i++) {
	var _lvl = _lvl_onscreen[i];
	if _lvl.tiles_back != -1 {
		draw_tilemap(
			_lvl.tiles_back, 
			tilemap_get_x(_lvl.tiles_back) - _cam_x,
			tilemap_get_y(_lvl.tiles_back) - _cam_y
		);
	}
	if _lvl.tiles_back_glass != -1 {
		draw_tilemap(
			_lvl.tiles_back_glass, 
			tilemap_get_x(_lvl.tiles_back_glass) - _cam_x,
			tilemap_get_y(_lvl.tiles_back_glass) - _cam_y
		);
	}
	if _lvl.tiles_decor_under != -1 {
		draw_tilemap(
			_lvl.tiles_decor_under, 
			tilemap_get_x(_lvl.tiles_decor_under) - _cam_x,
			tilemap_get_y(_lvl.tiles_decor_under) - _cam_y
		);
	}
}

surface_reset_target();

if !surface_exists(surf_tiles) {
	surf_tiles = surface_create(WIDTH, HEIGHT);
}
surface_set_target(surf_tiles);
draw_clear_alpha(c_black, 0);

// draw tile layer

shader_set(shd_tiles);

var _matrix = matrix_build_identity();
var _matrix_ind = util_matrix_get_alignment();

for (var i = 0; i < array_length(_lvl_onscreen); i++) {
	var _lvl = _lvl_onscreen[i]
	matrix_scratch[matrix_ind.x] = _lvl.x - _cam_x;
	matrix_scratch[matrix_ind.y] = _lvl.y - _cam_y;
	matrix_set(matrix_world, matrix_scratch);
	if _lvl.vb_tiles_below != -1 {
		vertex_submit(_lvl.vb_tiles_below, pr_trianglelist, tileset_get_texture(tl_tiles));
	}
	if _lvl.vb_front != -1 {
		vertex_submit(_lvl.vb_front, pr_trianglelist, tileset_get_texture(tl_tiles));
	}
}
matrix_set(matrix_world, matrix_identity);

matrix_scratch[matrix_ind.x] = 0;
matrix_scratch[matrix_ind.y] = 0;

shader_reset();

for (var i = 0; i < array_length(_lvl_onscreen); i++) {
	var _lvl = _lvl_onscreen[i];
	if _lvl.tiles_tiles_above != -1 {
		draw_tilemap(
			_lvl.tiles_tiles_above, 
			tilemap_get_x(_lvl.tiles_tiles_above) - _cam_x,
			tilemap_get_y(_lvl.tiles_tiles_above) - _cam_y
		);
	}
	if _lvl.tiles_decor != -1 {
		draw_tilemap(
			_lvl.tiles_decor, 
			tilemap_get_x(_lvl.tiles_decor) - _cam_x,
			tilemap_get_y(_lvl.tiles_decor) - _cam_y
		);
	}
	if _lvl.tiles_spike != -1 {
		draw_tilemap(
			_lvl.tiles_spike, 
			tilemap_get_x(_lvl.tiles_spike) - _cam_x,
			tilemap_get_y(_lvl.tiles_spike) - _cam_y
		);
	}
}

surface_reset_target();

/*
note:
up to this point, the application surface consists of the level background tiles.
*/
