function vinput_Manager(_gamepad = 0, _deadzone = 0.3) constructor {
	gamepad := _gamepad;
	deadzone := _deadzone;
	
	consumed := false;
	
	inputs := {};
	
	static update := function () {
		var _inputs := variable_struct_get_names(inputs);
		for (var i = 0; i < array_length(_inputs); i++) {
			inputs[$ _inputs[i]].update();
		}
		self.consumed = false;
	};
	
	static create_input := function (_name) {
		var _input := new vinput_Input(self);
		inputs[$ _name] = _input;
		return _input;
	};
	
	static check := function (_name) {
		return !self.consumed && inputs[$ _name].check();
	};
	
	static check_pressed := function (_name, _buffer = undefined) {
		return !self.consumed && inputs[$ _name].check_pressed(_buffer);
	};
	
	static check_released := function (_name, _buffer = undefined) {
		return !self.consumed && inputs[$ _name].check_released(_buffer);
	};
	
	static check_stutter := function (_name, _initial_delay = undefined, _interval = undefined) {
		return !self.consumed && inputs[$ _name].check_stutter(_initial_delay, _interval);
	};
	
	static check_raw := function (_name) {
		return !self.consumed && inputs[$ _name].check_raw();
	};
	
	static consume := function () {
		self.consumed = true;
	};
}

function vinput_Input(_manager) constructor {
	manager := _manager;
	keys := [];
	time = 0;
	
	static update := function () {
		var _active = false;
		
		for (var i = 0, _len := array_length(self.keys); i < _len; i++) {
			if self.keys[i].check() {
				_active = true;
				break;
			}
		}
		
		if _active {
			if self.time <= 0 {
				self.time = 0;
			}
			self.time += 1;
		}
		else if self.time > 0 {
			self.time = -1;
		}
		else {
			self.time -= 1;
		}
	};
	
	static add_keyboard_key := function (_key) {
		var key := {
			button: _key
		};
		
		key.check := method(key, function () {
			return keyboard_check(button);
		});

		array_push(self.keys, key);
		
		return self;
	};
	
	static add_keyboard_axis := function (_key_l, _key_r) {
		var key := {
			button_left: _key_l,
			button_right: _key_r,
		};
		
		key.check := method(key, function () {
			return keyboard_check(button_right) - keyboard_check(button_left);
		});

		array_push(self.keys, key);
		
		return self;
	};
	
	static add_gamepad_button := function (_button) {
		var key := {
			creator: other,
			button: _button,
		};
		
		key.check := method(key, function () {
			return gamepad_button_check(creator.manager.gamepad, button);
		});

		array_push(self.keys, key);
		
		return self;
    };
	
	static add_gamepad_stick_virtual := function(_stick, _direction, _deadzone = 0) {
		var key := {
		    creator: other,
		    axis: _stick,
		    dir: _direction,
		    deadzone: _deadzone,
		};
		
		key.check := method(key, function () {
		    return gamepad_axis_value(self.creator.manager.gamepad, axis) * self.dir >= self.creator.manager.deadzone + self.deadzone;
		});

		array_push(self.keys, key);
		
		return self;
    };
	
	static add_gamepad_stick := function (_stick) {
		var key := {
		    creator: other,
		    axis: _stick,
		};
		
		key.check := method(key, function () {
			var _value := gamepad_axis_value(self.creator.manager.gamepad, axis);
			
			if abs(_value) < self.creator.manager.deadzone {
				return 0;
			}
		    
			return _value;
		});

		array_push(self.keys, key);
		
		return self;
    };
	
	static add_gamepad_shoulder_virtual := function (_button, _direction) {
		var key := {
		    creator: other,
		    button: _button,
		};
		
		key.check = method(key, function () {
		    return gamepad_button_value(self.creator.manager.gamepad, self.button) >= 0.2; // creator.manager.deadzone;
		});

		array_push(self.keys, key);
		
		return self;
    }
	
	static add_gamepad_shoulder := function (_button, _direction) {
		var key := {
		    creator: other,
		    button: _button,
		};
		
		key.check = method(key, function () {
			var _value := gamepad_button_value(self.creator.manager.gamepad, self.button);
			if _value < 0.2 { // self.creator.manager.deadzone
				return 0;
			}
		    return _value;
		});

		array_push(self.keys, key);
		
		return self;
    };
	
	static check := function () {
		return self.time > 0;
	};
	
	static check_pressed := function (_buffer = 1) {
		return 0 < self.time && self.time <= _buffer;
	};
	
	static check_released := function (_buffer = 1) {
		return -_buffer - 1 < self.time && self.time < 0;
	};
	
	static check_stutter := function (_initial_delay, _interval) {
		if self.time == 1 {
			return true;
		}
		return self.time - _initial_delay > 0 && (self.time - _initial_delay) % _interval == 0;
	};
	
	static check_raw := function () {
		for (var i = 0, _len := array_length(self.keys); i < _len; i++) {
			var _value := self.keys[i].check();
			
			if _value != 0 {
				return _value;
			}
		}
		
		return 0;
	};
}
