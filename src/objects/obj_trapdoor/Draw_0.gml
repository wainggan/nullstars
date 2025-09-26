
var _key = level_get_instance(ref);
if locked_anim != 0 && instance_exists(_key) {
	var _start_x = _key.x;
	var _start_y = _key.y;
	
	var _target_x = x + sprite_width / 2;
	var _target_y = y + sprite_height / 2;
	
	var _dist = point_distance(_start_x, _start_y, _target_x, _target_y);
	var _dist_meow = _dist div 32;
	
	for (var i = 0; i < _dist_meow; i++) {
		var _x = terp(_start_x, _target_x, Tween.Ease, ((global.time + i * 32) / _dist) % 1);
		var _y = terp(_start_y, _target_y, Tween.Back, ((global.time + i * 32) / _dist) % 1);
		draw_circle_sprite(_x, _y, 8 * locked_anim, c_white, 1);
	}
}

