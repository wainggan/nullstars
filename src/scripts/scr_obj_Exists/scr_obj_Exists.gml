
function exists_outside_default() {
	static __fn = function(_cam = game_camera_get()) {
		static __pad = 64;
		return !rectangle_in_rectangle(
			bbox_right, bbox_top, bbox_left, bbox_bottom,
			_cam.x - __pad, _cam.y - __pad,
			_cam.x + _cam.w + __pad,
			_cam.y + _cam.h + __pad
		);
	};
	return __fn;
}

function exists_outside_empty() {
	static __fn = function() {
		return false;
	};
	return __fn;
}

