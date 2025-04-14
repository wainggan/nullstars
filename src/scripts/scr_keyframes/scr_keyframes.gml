
function Timeline() constructor {
	
	keyframes = [];
	current = 0;
	
	/// @arg {struct.Keyframe} _keyframe
	/// @return struct.Timeline
	static add = function (_keyframe) {
		array_push(self.keyframes, _keyframe);
		return self;
	};
	
	static update = function () {
		if self.complete() {
			return;
		}
		
		var _status = self.keyframes[self.current].process();
		if _status {
			self.current += 1;
		}
	};
	
	static complete = function () {
		return self.current >= array_length(self.keyframes);
	};
	
}

function Keyframe() constructor {
	static process = function () {
		return true;
	};
}

function KeyframeCallback(_callback) : Keyframe() constructor {
	assert(is_callable(_callback));
	callback = _callback;
	static process = function () {
		return callback() ?? true;
	};
}

function KeyframeTimedCallback(_time, _callback) : Keyframe() constructor {
	assert(is_real(_time));
	assert(_time >= 0);
	assert(is_callable(_callback));
	time = _time;
	callback = _callback;
	static process = function () {
		time -= 1;
		if time <= 0 {
			return callback() ?? true;
		} else {
			return false;
		}
	};
}

