/*
internal assertion api.

these must not be used for validating user input. these should only be used to validate internal invariants.
enabling the release flag will disable all assertions.
*/

#macro __ASSERT for (var __assert_check__ = undefined;; { if __assert_check__ != undefined { LOG(Log.Error, __assert_check__); LOG(Log.Error, string(debug_get_callstack())); throw __assert_concat__(_GMFILE_, _GMLINE_, __assert_check__); } break; }) __assert_check__ =

#macro __ASSERT_DEBUG if RELEASE {} else __ASSERT

#macro ASSERT __ASSERT __assert__

#macro ASSERT_DEBUG __ASSERT_DEBUG __assert__

function __assert__(_bool, _msg = "") {
	if _bool {
		return undefined;
	}
	else {
		return _msg;
	}
}

// gamemaker likes to remove string interpolation when they're inside a macro I guess.
// this has been a bug for months.
function __assert_concat__(_file, _line, _msg) {
	return $"assertion failed @ {_file}:{_line} :: {_msg}";
}

#macro ASSERT_EQ __ASSERT __assert_eq__

#macro ASSERT_EQ_DEBUG __ASSERT_DEBUG __assert_eq__

function __assert_eq__(_left, _right, _msg = "") {
	if _left == _right {
		return undefined;
	}
	else {
		return $"left == right: left = {_left}, right = {_right}. {_msg}";
	}
}

#macro ASSERT_NE __ASSERT __assert_ne__

#macro ASSERT_NE_DEBUG __ASSERT_DEBUG __assert_ne__

function __assert_ne__(_left, _right, _msg = "") {
	if _left != _right {
		return undefined;
	}
	else {
		return $"left != right: left = {_left}, right = {_right}. {_msg}";
	}
}
