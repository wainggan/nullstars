
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

function KeyframeRespawn(_force = false, _pre = false) : Keyframe() constructor {
	checkpoint = noone;
	state = 0;
	pet = noone;
	force = _force;
	pre = _pre;
	
	player_x = undefined;
	player_y = undefined;
	
	static set_pos = function (_x, _y) {
		player_x = _x;
		player_y = _y;
		return self;
	};
	
	static init = function () {
		checkpoint = game_checkpoint_ref();
		ASSERT(instance_exists(checkpoint));
		
		var _fade = false;
		
		if instance_exists(obj_player) || player_x != undefined {
			if player_x == undefined {
				player_x = obj_player.x;
				player_y = obj_player.y;
				
			}
			var _dist = point_distance(player_x, player_y, checkpoint.x, checkpoint.y);
			if _dist > GAME_RESPAWN_FADE_THRESHOLD {
				_fade = true;
			}
			instance_destroy(obj_player);
		} else {
			_fade = true;
		}
		
		_fade = _fade || force;
		
		if _fade {
			pet = instance_create_layer(0, 0, "Instances", obj_flag_blackout);
			if pre {
				pet.time = 1;
				state = 1;
			} else {
				pet.time = 0;
				state = 0;
			}
		} else {
			state = 7;
		}
	};
	static tick = function () {
		var _x_target = checkpoint.x;
		var _y_target = checkpoint.y;
		
		if state == 0 {
			pet.time = approach(pet.time, 1, 0.1);
			if pet.time == 1 {
				state = 1;
			}
		} else if state == 1 {
			global.game.camera.move(_x_target, _y_target, false);
			state = 2;
		} else if state == 2 {
			if array_length(global.game.level.queue) == 0 {
				state = 3;
			}
		} else if state == 3 {
			var _constrain = global.game.camera.constrain(_x_target, _y_target);
			global.game.camera.move(_constrain.x, _constrain.y, false);
			state = 4;
		} else if state == 4 {
			if array_length(global.game.level.queue) == 0 {
				state = 5;
			}
		} else if state == 5 {
			instance_create_layer(_x_target, _y_target - 16, "Instances", obj_player);
			state = 6;
		} else if state == 6 {
			pet.time = approach(pet.time, 0, 0.1);
			if pet.time == 0 {
				return true;
			}
		} else if state == 7 {
			instance_create_layer(_x_target, _y_target, "Instances", obj_player);
			return true;
		} else {
			ASSERT(false);
		}
		
		return false;
	};
}


