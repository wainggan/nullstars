
function Camera() constructor {
	x = 0;
	y = 0;
	
	static tick := function () {
		camera_set_view_pos(view_camera[0], x - (WINDOW_WIDTH) / 2, y - (WINDOW_HEIGHT) / 2);
	};
}

function ns_cam_get() {
	static __cache := {
		x: 0,
		y: 0,
		w: WINDOW_WIDTH,
		h: WINDOW_HEIGHT,
	};
	
	__cache.x = camera_get_view_x(view_camera[0]);
	__cache.y = camera_get_view_y(view_camera[0]);
	
	return __cache;
}

