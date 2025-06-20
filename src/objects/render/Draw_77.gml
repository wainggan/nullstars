
var _cam_x = camera_get_view_x(view_camera[0]),
	_cam_y = camera_get_view_y(view_camera[0]),
	_cam_w = camera_get_view_width(view_camera[0]),
	_cam_h = camera_get_view_height(view_camera[0])

var _lvl_onscreen = game_level_onscreen()

var _scale_w = window_get_width() / _cam_w,
	_scale_h = window_get_height() / _cam_h


if global.config.graphics_post_outline {
	surface_set_target(surf_layer_outline);
	draw_clear_alpha(c_black, 0);
	
	draw_surface_ext(surf_layer_0, 0, 0, 1, 1, 0, c_black, 1);
	
	gpu_set_blendmode(bm_subtract);
		for (var i = 0; i < array_length(_lvl_onscreen); i++) {
			var _lvl = _lvl_onscreen[i];
			if _lvl.tiles_back_glass != -1 {
				draw_tilemap(
					_lvl.tiles_back_glass, 
					tilemap_get_x(_lvl.tiles_back_glass) - _cam_x,
					tilemap_get_y(_lvl.tiles_back_glass) - _cam_y
				);
			}
		}
	gpu_set_blendmode(bm_normal);
	
	draw_surface_ext(surf_layer_2, 0, 0, 1, 1, 0, c_black, 1);
	
	surface_reset_target();
}


surface_set_target(surf_compose)
draw_clear_alpha(c_black, 1);

draw_sprite_ext(
	spr_pixel, 0, 
	0, 0, 
	_cam_w, _cam_h, 
	0, #000209, 1
);

surface_set_target(surf_ping);
draw_clear_alpha(c_black, 0);
matrix_scratch[matrix_ind.x] = -_cam_x;
matrix_scratch[matrix_ind.y] = -_cam_y;
matrix_set(matrix_world, matrix_scratch);
with obj_decor_glowable {
	event_perform(ev_draw, 0);
}
var _beat = (1 + power(1 - game_music_get_beat(2), 2) * 0.1);
with obj_timer_start {
	var _dir = anim_dir * 90;
	var _scale = _beat * tween(Tween.Back, anim_complete);
	draw_sprite_ext(
		spr_timer_star, 0,
		x + sprite_width / 2 - lengthdir_x(8, _dir),
		y + sprite_height / 2 - lengthdir_y(8, _dir),
		_scale,
		_scale,
		0, #99bbbb, 1
	);
}
matrix_set(matrix_world, matrix_identity);
matrix_scratch[matrix_ind.x] = 0;
matrix_scratch[matrix_ind.y] = 0;
surface_reset_target();

gpu_set_colorwriteenable(true, true, true, false);

draw_surface_ext(surf_background, 0, 0, 1, 1, 0, c_white, 1);

if global.config.graphics_post_outline {

	shader_set(shd_outline_post);
	var _u_texel = shader_get_uniform(shd_outline_post, "u_texel");
	shader_set_uniform_f(_u_texel, 1 / WIDTH, 1 / HEIGHT);

	draw_surface_ext(surf_layer_outline, 0, 0, 1, 1, 0, c_black, 1);
	
	shader_reset();
	
	draw_surface_ext(surf_layer_0, 0, 0, 1, 1, 0, c_white, 1);
	
	game_render_refresh();
	game_render_blendmode_set(shd_blend_colordodge);
	draw_surface(surf_ping, 0, 0);
	game_render_blendmode_reset();
	
	draw_surface_ext(surf_layer_1, 0, 0, 1, 1, 0, c_white, 1);
	draw_surface_ext(surf_layer_2, 0, 0, 1, 1, 0, c_white, 1);

} else {
	
	draw_surface_ext(surf_layer_0, 0, 0, 1, 1, 0, c_white, 1);
	draw_surface_ext(surf_layer_1, 0, 0, 1, 1, 0, c_white, 1);
	draw_surface_ext(surf_layer_2, 0, 0, 1, 1, 0, c_white, 1);
	
}

gpu_set_tex_filter(true);

gpu_set_blendmode(bm_add);
draw_sprite_tiled_ext(spr_atmosphere_clouds, 0, -_cam_x * 0.5, -_cam_y * 0.5 + (global.time / 4), 24, 24, #111111, 1);
gpu_set_blendmode(bm_normal);

game_render_refresh();
game_render_blendmode_set(shd_blend_overlay);
draw_sprite_tiled_ext(spr_atmosphere_clouds, 0, -_cam_x * 0.6, -_cam_y * 0.6 + (global.time / 2), 18, 18, #ffffff, 0.4);
game_render_blendmode_reset();

gpu_set_tex_filter(false);

gpu_set_colorwriteenable(true, true, true, true);

surface_reset_target();


if instance_number(obj_effect_wave) == 0 || global.settings.graphic.distortion == 0 {
} else {
	
	surface_set_target(surf_ping);
	draw_surface(surf_compose, 0, 0);
	surface_reset_target();
	
	var _surf_wave_scale = 1 / 2;
	
	if !surface_exists(surf_wave) {
		surf_wave = surface_create(WIDTH * _surf_wave_scale, HEIGHT * _surf_wave_scale);
	}
	
	gpu_set_tex_filter(true);
	
	surface_set_target(surf_wave);
		draw_clear_alpha(#7f7fff, 1);
	gpu_set_blendmode_ext(bm_dest_color, bm_src_color);
	shader_set(shd_wave_normals);
	
	with obj_effect_wave {
		draw_sprite_ext(
			sprite, 0,
			(x - _cam_x) * _surf_wave_scale,
			(y - _cam_y) * _surf_wave_scale,
			scale / 512 * _surf_wave_scale, scale / 512 * _surf_wave_scale, 0,
			c_white, alpha
		);
	}
	
	shader_reset();
	gpu_set_blendmode(bm_normal);
	surface_reset_target();
	
	gpu_set_tex_filter(false);
	
	var _u_normals = shader_get_sampler_index(shd_wave_distort, "u_normals");
	var _u_strength = shader_get_uniform(shd_wave_distort, "u_strength");
	var _u_aspect = shader_get_uniform(shd_wave_distort, "u_aspect");
	
	surface_set_target(surf_compose);
	shader_set(shd_wave_distort);
	shader_set_uniform_f(_u_strength, 0.025);
	shader_set_uniform_f(_u_aspect, WIDTH / HEIGHT);
	texture_set_stage(_u_normals, surface_get_texture(surf_wave));
		draw_surface(surf_ping, 0, 0);
	shader_reset();
	surface_reset_target();
}

if global.settings.graphic.cracks != 0 {
	surface_set_target(surf_ping);

	var _u_time = shader_get_uniform(shd_edgeglitch, "u_time");
	var _u_texel = shader_get_uniform(shd_edgeglitch, "u_texel");

	shader_set(shd_edgeglitch);

	shader_set_uniform_f(_u_time, global.time / 60);
	shader_set_uniform_f(_u_texel, 1 / WIDTH, 1 / HEIGHT);

	draw_surface(surf_compose, 0, 0);

	shader_reset();
	surface_reset_target();

	surface_set_target(surf_compose);
	draw_surface(surf_ping, 0, 0);
	surface_reset_target();
}

if global.settings.graphic.bloom != 0 {
	var _u_threshold = shader_get_uniform(shd_bloom_filter, "u_threshold");
	var _u_range = shader_get_uniform(shd_bloom_filter, "u_range");

	surface_set_target(surf_ping);
	shader_set(shd_bloom_filter);
		shader_set_uniform_f(_u_threshold, 0.4);
		shader_set_uniform_f(_u_range, 0.3);

	draw_surface(surf_compose, 0, 0);

	shader_reset();
	surface_reset_target();

	var _u_kernel = shader_get_uniform(shd_blur, "u_kernel")
	var _u_sigma = shader_get_uniform(shd_blur, "u_sigma")
	var _u_direction = shader_get_uniform(shd_blur, "u_direction")
	var _u_texel = shader_get_uniform(shd_blur, "u_texel")

	shader_set(shd_blur);

	shader_set_uniform_f(_u_kernel, 7);
	shader_set_uniform_f(_u_sigma, 0.2);
	shader_set_uniform_f(_u_texel, 1 / _cam_w, 1 / _cam_h);

	shader_set_uniform_f(_u_direction, 0, 1);

	surface_set_target(surf_pong);
	draw_surface(surf_ping, 0, 0);
	surface_reset_target();

	shader_set_uniform_f(_u_direction, 1, 0);

	surface_set_target(surf_ping);
	draw_surface(surf_pong, 0, 0);
	surface_reset_target();

	shader_reset();

	surface_set_target(surf_compose);
	gpu_set_colorwriteenable(true, true, true, false);
	gpu_set_blendmode(bm_add);
	draw_surface_ext(surf_ping, 0, 0, 1, 1, 0, #7788ff, 0.2);
	gpu_set_blendmode(bm_normal);
	gpu_set_colorwriteenable(true, true, true, true);
	surface_reset_target();
}


if global.settings.graphic.abberation != 0 {
	surface_set_target(surf_ping);

	var _u_resolution = shader_get_uniform(shd_abberation, "u_resolution");
	var _u_strength = shader_get_uniform(shd_abberation, "u_strength");

	shader_set(shd_abberation);

	shader_set_uniform_f(_u_resolution, WIDTH, HEIGHT);
	shader_set_uniform_f(_u_strength, 1 / WIDTH);

	draw_surface(surf_compose, 0, 0);

	shader_reset();
	surface_reset_target();

	surface_set_target(surf_compose);
	draw_surface(surf_ping, 0, 0);
	surface_reset_target();
}

with obj_flag_blackout {
	surface_set_target(other.surf_compose);
	draw_sprite_ext(spr_pixel, 0, 0, 0, WIDTH, HEIGHT, 0, c_black, time);
	surface_reset_target();
}

if global.config.graphics_post_grading {

	if !surface_exists(surf_lut)
		surf_lut = surface_create(256, 16)

	surface_set_target(surf_lut)
	draw_clear_alpha(c_black, 1)
	gpu_set_colorwriteenable(true, true, true, false);
		var _lut_grade = lut_mode_grade.get()
		var _lut_mix = lut_mode_mix.get()
		var _lut_mix_value = lerp(_lut_mix.current, _lut_mix.target, _lut_mix.progress);
		draw_sprite(spr_grade_base, 0, 0, 0);
		draw_sprite_ext(
			_lut_grade.current, 0, 0, 0, 1, 1, 0, c_white, 
			_lut_mix_value * (1 - _lut_grade.progress)
		);
		draw_sprite_ext(
			_lut_grade.target, 0, 0, 0, 1, 1, 0, c_white, 
			_lut_mix_value * _lut_grade.progress
		);
	gpu_set_colorwriteenable(true, true, true, true);
	surface_reset_target()

	var _u_strength = shader_get_uniform(shd_grade, "u_strength");
	var _u_lut = shader_get_sampler_index(shd_grade, "u_lut");

	gpu_set_tex_filter_ext(_u_lut, true)
	shader_set(shd_grade);
	surface_set_target(application_surface); // lmao

		shader_set_uniform_f(_u_strength, 1)
		texture_set_stage(_u_lut, surface_get_texture(surf_lut));

		draw_surface_ext(surf_compose, 0, 0, 1, 1, 0, c_white, 1);

	surface_reset_target();
	shader_reset();
	gpu_set_tex_filter(false)

} else {

	surface_set_target(application_surface);
	draw_surface_ext(surf_compose, 0, 0, 1, 1, 0, c_white, 1);
	surface_reset_target();
	
}

draw_surface_ext(application_surface, 0, 0, _scale_w, _scale_h, 0, c_white, 1);

