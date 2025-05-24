
function Timeline() constructor {
	keyframes = [];
	current = 0;
	
	/// @arg {struct.Keyframe} _keyframe
	/// @return struct.Timeline
	static add = function (_keyframe) {
		array_push(self.keyframes, _keyframe);
		return self;
	};
	
	static tick = function () {
		if self.complete() {
			return;
		}
		
		var _key = self.keyframes[self.current];
		
		if !_key.__init {
			_key.init();
			_key.__init = true;
		}
		
		var _status = _key.tick();
		if _status {
			self.current += 1;
		}
	};
	
	static complete = function () {
		return self.current >= array_length(self.keyframes);
	};
}

function Keyframe() constructor {
	/// @ignore
	__init = false;
	static init = function () {};
	static tick = function () {
		return true;
	};
}

/// @arg {real} _time
function KeyframeTimed(_time) : Keyframe() constructor {
	ASSERT(_time >= 0);
	
	time = _time;
	
	static tick = function () {
		time -= 1;
		if time <= 0 {
			return true;
		} else {
			return false;
		}
	};
}

/// @arg {function} _callback
function KeyframeCallback(_callback) : Keyframe() constructor {
	callback = _callback;
	
	static tick = function () {
		return callback() ?? true;
	};
}

/// @arg {real} _time
/// @arg {function} _callback
function KeyframeTimedCallback(_time, _callback) : Keyframe() constructor {
	ASSERT(_time >= 0);
	
	time = _time;
	callback = _callback;
	
	static tick = function () {
		time -= 1;
		if time <= 0 {
			return callback() ?? true;
		} else {
			return false;
		}
	};
}


/// @arg {real} _from_x
/// @arg {real} _from_y
/// @arg {real} _to_x
/// @arg {real} _to_y
/// @arg {real} _speed
function KeyframeCamera(_from_x, _from_y, _to_x, _to_y, _speed) : Keyframe() constructor {
	
	x_start = _from_x;
	y_start = _from_y;
	x = x_start;
	y = y_start;
	x_target = _to_x;
	y_target = _to_y;
	progress = 0;
	speed = _speed;
	
	// @todo: hook camera
	static init = function () {
		
	};
	
	static tick = function () {
		progress = approach(progress, 1, speed);
		x = lerp(x_start, x_target, progress);
		y = lerp(y_start, y_target, progress);
		if progress == 1 {
			return true;
		} else {
			return false;
		}
	};
}

function KeyframeRespawn() : Keyframe() constructor {
	// @todo:
	static init = function () {
		instance_destroy(obj_player);
	};
	static tick = function () {
		var _checkpoint = game_checkpoint_ref();

		var _x_target = _checkpoint.x;
		var _y_target = _checkpoint.y;
		
		instance_create_layer(_x_target, _y_target, "Instances", obj_player);
		
		return true;
	};
}


