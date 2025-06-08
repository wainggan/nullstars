 
var _cam = game_camera_get()
var _pad = WIDTH;

var _amount = irandom(2) + 1;

while _amount-- > 0 {
	var _p_x = irandom_range(_cam.x - _pad, _cam.x + _cam.w + _pad),
		_p_y = irandom_range(_cam.y - _pad, _cam.y + _cam.h + _pad);
	var _level = game_level_get_safe(_p_x, _p_y);
	
	if _level && _level.loaded {
		
		var _t_x = (_p_x - _level.x) div TILESIZE;
		var _t_y = (_p_y - _level.y) div TILESIZE;
		
		if tilemap_get(_level.tiles, _t_x, _t_y) == 0 {
			
			var i_check = 0;
			var _found = false;
			for (; i_check < 16; i_check++) {
				if tilemap_get(_level.tiles, _t_x, _t_y + i_check) != 0 {
					_found = true;
					break;
				}
			}
			
			_t_y += i_check;
			
			if _found {
				var _space_l = 0;
				for (var j_check = 1; j_check < 4; j_check++) {
					if tilemap_get(_level.tiles, _t_x - j_check, _t_y) == 0
						|| tilemap_get(_level.tiles, _t_x + j_check, _t_y - 1) != 0 {
						break;
					}
					_space_l++;
				}
				
				var _space_r = 0;
				for (var j_check = 1; j_check < 4; j_check++) {
					if tilemap_get(_level.tiles, _t_x + j_check, _t_y) == 0
						|| tilemap_get(_level.tiles, _t_x + j_check, _t_y - 1) != 0 {
						break;
					}
					_space_r++;
				}
				
				var _space = min(_space_l, _space_r);
				_space = max(_space, 1);
				
				if _space != 1 {
					_space = _space * 2 - 1;
				}
	
				var _o_x = _t_x * TILESIZE + _level.x;
				var _o_y = _t_y * TILESIZE + _level.y;
				
				with instance_create_layer(
					_o_x, _o_y + 1,
					"Instances", obj_decor_puddle) {
					image_xscale = _space;
					x = x - sprite_width / 2 - TILESIZE / 2;
					height = random_range(0.7, 1.5);
				}
			}
			
		}
	}
}

timer -= 1;
if timer <= 0 {
	instance_destroy();
}

