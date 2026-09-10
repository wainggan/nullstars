
/// smoothstep-style interpolation
/// @arg {real} _t number from 0-1 to remap
/// @return {real}
/// @pure
function hermite(_t) {
	gml_pragma("forceinline");
    return _t * _t * (3.0 - 2.0 * _t);
}

/// herpes smoothstep
/// @pure
function herp(_a, _b, _t) {
	gml_pragma("forceinline");
	return lerp(_a, _b, hermite(_t));
}

enum Tween {
	Linear = 0,
	Ease,
	Cubic,
	Quart,
	Expo,
	Circ,
	Back,
	Elastic,
	Bounce,
	FastSlow,
	MidSlow
}

/// @arg {enum.Tween} _index
/// @arg {real} _t
function tween(_index, _t) {
	gml_pragma("forceinline");
	var _channel = animcurve_get_channel(ac_tween, _index);
	return animcurve_channel_evaluate(_channel, _t);
}

/// @arg {enum.Tween} _index
/// @arg {real} _a
/// @arg {real} _b
/// @arg {real} _t
function terp(_index, _a, _b, _t) {
	gml_pragma("forceinline");
	return lerp(_a, _b, tween(_index, _t));
}

