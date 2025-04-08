
var _cam = game_camera_get();

var _pad = 6;

if state.is(state_idle) {
	// todo:
	draw_sprite_tiled_area(
		spr_spike_pond_fill, 0,
		wave(-32, 32, 12), wave(-24, 24, 10, 0.5),
		min(x, anim_sight_x) + 6, min(y, anim_sight_y) + _pad,
		max(x, anim_sight_x) + sprite_width - 6, max(y, anim_sight_y) + sprite_height - _pad
	);
}

var _anim = 0;
if state.is(state_idle) {
	_anim = 1;
} else {
	anim_line = approach(anim_line, 0, 0.1);
	_anim = tween(Tween.FastSlow, anim_line);
}

var _di = round(dir / 90);
switch _di {
	case 0:
	case 2: {
		var _x0 = min(x, anim_sight_x) + 6;
		var _x1 = max(x, anim_sight_x) + sprite_width - 6;
		
		var _nx0 = _x0;
		var _nx1 = _x1;
		
		if _di == 0 {
			_nx0 = lerp(_x0, _x1, 1 - _anim);
		} else {
			_nx1 = lerp(_x1, _x0, 1 - _anim);
		}
		
		draw_line_sprite(
			_nx0, y + _pad,
			_nx1, y + _pad
		);
		draw_line_sprite(
			_nx0, y + sprite_height - _pad,
			_nx1, y + sprite_height - _pad
		);
	} break;
	case 1:
	case 3: {
		var _y0 = min(y, anim_sight_y) + 6;
		var _y1 = max(y, anim_sight_y) + sprite_height - 6;
		
		var _ny0 = _y0;
		var _ny1 = _y1;
		
		if _di == 3 {
			_ny0 = lerp(_y0, _y1, 1 - _anim);
		} else {
			_ny1 = lerp(_y1, _y0, 1 - _anim);
		}
		
		draw_line_sprite(
			x + _pad, _ny0,
			x + _pad, _ny1
		);
		draw_line_sprite(
			x + sprite_width - _pad, _ny0,
			x + sprite_width - _pad, _ny1
		);
	} break;
}

