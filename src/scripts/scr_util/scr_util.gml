
#macro ASSERT if RELEASE {} else for (var __check__ = true;; { if !__check__ { throw $"assertion failed @ {_GMFILE_}:{_GMLINE_} :: found {__check__}"; } break; }) __check__ =


/// moves `a` to `b` by `amount` without overshooting
/// @arg {real} _a starting value
/// @arg {real} _b ending value
/// @arg {real} _amount positive number to move by
/// @return {real}
/// @pure
function approach(_a, _b, _amount) {
	gml_pragma("forceinline");
	if (_a < _b)
	    return min(_a + _amount, _b); 
	else
	    return max(_a - _amount, _b);
}

/// @pure
function floor_ext(_value, _round) {
	gml_pragma("forceinline");
	if _round <= 0 return _value;
	return floor(_value / _round) * _round;
}
/// @pure
function ceil_ext(_value, _round) {
	gml_pragma("forceinline");
	if _round <= 0 return _value;
	return ceil(_value / _round) * _round;
}
/// @pure
function round_ext(_value, _round) {
	gml_pragma("forceinline");
	if _round <= 0 return _value;
	return round(_value / _round) * _round;
}

/// modulo `value` by `by` such that the result is always positive,
/// using euclidean division: https://en.wikipedia.org/wiki/Modulo
/// @arg {real} _value dividend
/// @arg {real} _by divisor
/// @return {real}
/// @pure
function mod_euclidean(_value, _by) {
	gml_pragma("forceinline");
	return _value - abs(_by) * floor(_value / abs(_by))
}

/// @pure
function map(_value, _start_low, _start_high, _target_low, _target_high) {
	gml_pragma("forceinline");
    return ((_value - _start_low) / (_start_high - _start_low)) * (_target_high - _target_low) + _target_low;
}

/// wrapper for `sin()`.
/// sin wave from `from` to `to`, with `duration` long period.
/// @arg {real} _from
/// @arg {real} _to
/// @arg {real} _duration
/// @arg {real} _offset
/// @arg {real} _time
/// @return {real}
/// @pure
function wave(_from, _to, _duration, _offset = 0, _time = global.time / 60) {
	gml_pragma("forceinline");
	var _a4 = (_from - _to) * 0.5;
	return _to + _a4 + sin(((_time + _duration) / _duration + _offset) * (pi*2)) * _a4;
}

/// @pure
function wrap(_value, _min, _max) {
	gml_pragma("forceinline");
	_value = floor(_value);
	var _low = floor(min(_min, _max));
	var _high = floor(max(_min, _max));
	var _range = _high - _low + 1;

	return (((floor(_value) - _low) % _range) + _range) % _range + _low;
}

/// @pure
function chance(_percent) {
	gml_pragma("forceinline");
	return _percent > random(1);
}

/// @pure
function parabola(_p1, _p2, _height, _off) {
	gml_pragma("forceinline");
	return -(_height / power((_p1 - _p2) / 2, 2)) * (_off - _p1) * (_off - _p2)
}
/// @pure
function parabola_mid(_center, _size, _height, _off) {
	gml_pragma("forceinline");
	return parabola(_center - _size, _center + _size, _height, _off)
}
/// @pure
function parabola_mid_edge(_center, _p, _height, _off) {
	gml_pragma("forceinline");
	return parabola(_center - (_p - _center), _p, _height, _off)
}

/// smoothstep-style interpolation
/// @arg {real} _t number from 0-1 to remap
/// @return {real}
/// @pure
function hermite(_t) {
	gml_pragma("forceinline");
    return _t * _t * (3.0 - 2.0 * _t);
}
/// smoothstep
/// @pure
function herp(_a, _b, _t) {
	gml_pragma("forceinline");
	return lerp(_a, _b, hermite(_t));
}

function struct_assign(_target, _assign) {
	var _names = struct_get_names(_assign);
	for (var i = 0; i < array_length(_names); i++) {
		_target[$ _names[i]] = _assign[$ _names[i]]
	}
	return _target;
}

/// @arg {id.DsList} _list
/// @return Array<Any>
function array_from_list(_list) {
	var _array = array_create(ds_list_size(_list));
	for (var i = 0; i < ds_list_size(_list); i++) {
		_array[i] = _list[| i];
	}
	return _array;
}

/// @arg {Real} _x
/// @arg {Real} _y
/// @arg {Any} _obj
/// @arg {Bool} _ordered
/// @return Array<Any>
function instance_place_array(_x, _y, _obj, _ordered) {
	static __list = ds_list_create();
	ds_list_clear(__list);
	instance_place_list(_x, _y, _obj, __list, _ordered);
	var _array = array_from_list(_list);
	return _array;
}

/// @pure
function multiply_color(_c1, _c2) {
	gml_pragma("forceinline");
	return _c1 * _c2 / #ffffff;
}

// for the one time i need this
function hex_to_dec(_hex) {
    var _dec = 0;
 
    static _dig = "0123456789ABCDEF";
    var _len = string_length(_hex);
    for (var i = 1; i <= _len; i += 1) {
        _dec = _dec << 4 | (string_pos(string_char_at(_hex, i), _dig) - 1);
    }
 
    return _dec;
}

function array_kick(_array, _index) {
	gml_pragma("forceinline");
	_array[_index] = _array[array_length(_array) - 1];
	array_pop(_array);
}

function variable_ref_create(_inst, _name) {
	with { _inst, _name } return function() {
		if (argument_count > 0) {
			variable_instance_set(_inst, _name, argument[0]);
		} else return variable_instance_get(_inst, _name);
	}
}

function array_ref_create(_array, _index) {
	with { _array, _index } return function() {
		if (argument_count > 0) {
			_array[_index] = argument[0];
		} else return _array[_index];
	}
}

/// smooth min.
/// finds the minimum between _a and _b, smoothed by _k.
/// 
/// returns 2 values. [0] is the minimum, and [1] is a number
/// from 0-1 representing how much of _a or _b is in the minimum.
/// array must be used before another call to smin().
/// @arg {Real} _a
/// @arg {Real} _b
/// @arg {Real} _k
/// @return Array<Real>
function smin(_a, _b, _k) {
	static __out = array_create(2);
	
	var _h = 1 - min(abs(_a - _b) / (6 * _k), 1);
	var _w = power(_h, 3);
	var _m = _w * 0.5;
	var _s = _w * _k;
	
	if _a < _b {
		__out[0] = _a - _s;
		__out[1] = _m;
		return __out;
	} else {
		__out[0] = _b - _s;
		__out[1] = 1 - _m;
		return __out;
	}
}

/// hard min.
/// finds the minimum between _a and _b
/// 
/// similar api to smin(), for utility.
/// 
/// @arg {Real} _a
/// @arg {Real} _b
/// 
/// @return Array<Real>
function hmin(_a, _b) {
	static __out = array_create(2);
	
	if _a < _b {
		__out[0] = _a;
		__out[1] = 0;
		return __out;
	} else {
		__out[0] = _b;
		__out[1] = 1;
		return __out;
	}
}

/// rectangle sdf function.
/// 
/// @arg {Real} _px point x
/// @arg {Real} _py point y
/// @arg {Real} _rx0 rectangle left x
/// @arg {Real} _ry0 rectangle upper y
/// @arg {Real} _rx1 rectangle right x
/// @arg {Real} _ry1 rectangle lower y
/// 
/// @return Real
function sdf(_px, _py, _rx0, _ry0, _rx1, _ry1) {
	var _dx = max(_rx0 - _px, _px - _rx1);
	var _dy = max(_ry0 - _py, _py - _ry1);
	var _dd = min(0.0, max(_dx, _dy));
	return sqrt(power(max(0, _dx), 2) + power(max(0, _dy), 2)) + _dd;
}

function draw_sprite_tiled_area(_sprite, _subimg, _xx, _yy, _x1, _y1, _x2, _y2) {
	draw_sprite_tiled_area_ext(_sprite, _subimg, _xx, _yy, _x1, _y1, _x2, _y2, c_white, 1);
}

// https://gmlscripts.com/script/draw_sprite_tiled_area
function draw_sprite_tiled_area_ext(_sprite, _subimg, _xx, _yy, _x1, _y1, _x2, _y2, _colour, _alpha) {
	
	var _sw = sprite_get_width(_sprite);
	var _sh = sprite_get_height(_sprite);

	var i = _x1 - ((_x1 mod _sw) - (_xx mod _sw)) - _sw * +((_x1 mod _sw) < (_xx mod _sw));
	var j = _y1 - ((_y1 mod _sh) - (_yy mod _sh)) - _sh * +((_y1 mod _sh) < (_yy mod _sh)); 
	var jj = j;

	for(; i <= _x2; i += _sw) {
		for(; j <= _y2; j += _sh) {

			var _left = 0;
			if i <= _x1
				_left = _x1 - i;
			else
				_left = 0;
			var _x = i + _left;

			var _top = 0;
			if j <= _y1
				_top = _y1 - j;
			else
				_top = 0;
			var _y = j + _top;

			var _width = 0;
			if _x2 <= i + _sw
				_width = ((_sw) - (i + _sw - _x2) + 1) - _left;
			else
				_width = _sw - _left;

			var _height = 0;
			if _y2 <= j + _sh
				_height = ((_sh) - (j + _sh - _y2) + 1) - _top;
			else
				_height = _sh - _top;

			draw_sprite_part_ext(_sprite, _subimg, _left, _top, _width, _height, _x, _y, 1, 1, _colour, _alpha);
		}
		j = jj;
	}
	
}

