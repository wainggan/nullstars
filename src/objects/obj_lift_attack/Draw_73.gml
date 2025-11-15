
draw_sprite_ext(spr_lift_attack, 0, x, y, image_xscale, image_yscale, 0, c_white, 1);

var _center_x = x + sprite_width / 2;
var _center_y = y + sprite_height / 2;

var _di = dir; // going to kill myself

var _anim = (anim_frame / 4 % 32);

var _off_x = _center_x;
var _off_y = _center_y;

var _bbl = 0;
var _bbr = 0;
var _bbt = 0;
var _bbb = 0;
switch _di {
	case 0:
	case 2: {
		_bbl = x + 8;
		_bbr = x + sprite_width - 8;
		_bbt = max(_center_y - 16, y + 8);
		_bbb = min(_center_y + 16, y + sprite_height - 8);
		
		if state.is(state_retract) {
			if _di == 0 {
				_di = 2;
			} else {
				_di = 0;
			}
		}
		
		if _di == 0 {
			_off_x += _anim;
		} else {
			_off_x -= _anim;
		}
	} break;
	case 1:
	case 3: {
		_bbl = max(_center_x - 16, x + 8);
		_bbr = min(_center_x + 16, x + sprite_width - 8);
		_bbt = y + 8;
		_bbb = y + sprite_height - 8;
		
		if state.is(state_retract) {
			if _di == 3 {
				_di = 1;
			} else {
				_di = 3;
			}
		}
		
		if _di == 3 {
			_off_y += _anim;
		} else {
			_off_y -= _anim
		}
	} break;
}


draw_sprite_tiled_area_ext(
	spr_lift_attack_direction, _di,
	_off_x - 16, _off_y - 16,
	_bbl, _bbt,
	_bbr - 1, _bbb - 1,
	state.is(state_retract) ? #777799 : c_white, 1
);

