/// moves `a` to `b` by `amount` without overshooting
/// @arg {real} _a starting value
/// @arg {real} _b ending value
/// @arg {real} _amount positive number to move by
/// @return {real}
/// @pure
function approach(_a, _b, _amount) {
	gml_pragma("forceinline");
	if (_a < _b) {
	    return min(_a + _amount, _b);
	}
	else {
	    return max(_a - _amount, _b);
	}
}

/// @pure
function floor_ext(_value, _round) {
	gml_pragma("forceinline");
	if _round <= 0 {
		return _value;
	}
	return floor(_value / _round) * _round;
}

/// @pure
function ceil_ext(_value, _round) {
	gml_pragma("forceinline");
	if _round <= 0 {
		return _value;
	}
	return ceil(_value / _round) * _round;
}

/// @pure
function round_ext(_value, _round) {
	gml_pragma("forceinline");
	if _round <= 0 {
		return _value;
	}
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
/// sine wave from `from` to `to`, with `duration` long period.
/// @arg {real} _from
/// @arg {real} _to
/// @arg {real} _duration
/// @arg {real} _offset
/// @arg {real} _time
/// @return {real}
/// @pure
function wave(_from, _to, _duration, _offset = 0, _time = global.time / 60) {
	gml_pragma("forceinline");
	var _a4 := (_from - _to) * 0.5;
	return _to + _a4 + sin(((_time + _duration) / _duration + _offset) * (pi*2)) * _a4;
}

/// @pure
function wrap(_value, _min, _max) {
	gml_pragma("forceinline");
	_value = floor(_value);
	var _low := floor(min(_min, _max));
	var _high := floor(max(_min, _max));
	var _range := _high - _low + 1;

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
	return -(_height / power((_p1 - _p2) / 2, 2)) * (_off - _p1) * (_off - _p2);
}

/// @pure
function parabola_mid(_center, _size, _height, _off) {
	gml_pragma("forceinline");
	return parabola(_center - _size, _center + _size, _height, _off);
}

/// @pure
function parabola_mid_edge(_center, _p, _height, _off) {
	gml_pragma("forceinline");
	return parabola(_center - (_p - _center), _p, _height, _off);
}

