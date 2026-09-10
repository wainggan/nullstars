
/// @arg {real} _f frequency
/// @arg {real} _z bounce
/// @arg {real} _r response
function Sod(_f = 1, _z = 1, _r = 0) constructor {
	self.k1 = 0;
	self.k2 = 0;
	self.k3 = 0;
    
	self.value = 0;
	self.value_vel = 0;
	self._lastX = 0;
    
	self.accurate = false;
	self._crit = 0;
	
	self.set_weights(_f, _z, _r);
	
	static set_k = function(_k1 = self.k1, _k2 = self.k2, _k3 = self.k3) {
		self.k1 = _k1;
		self.k2 = _k2;
		self.k3 = _k3;
		self._crit = 
		    self.accurate ? 0.8 * (sqrt(4 * self.k2 + power(self.k1, 2)) - self.k1) : undefined;
		return self;
	}
	
	/// @arg {real} _f frequency
	/// @arg {real} _z bounce
	/// @arg {real} _r response
	static set_weights = function(_f, _z, _r) {
		self.k1 = _z / (pi * _f);
		self.k2 = 1 / power(2 * pi * _f, 2);
		self.k3 = (_r * _z) / (2 * pi * _f);
		self._crit = 
			self.accurate ? 0.8 * (sqrt(4 * self.k2 + power(self.k1, 2)) - self.k1) : undefined;
		return self;
	}
	static set_accuracy = function(_v = true) {
		self.accurate = _v;
		self._crit = 
			self.accurate ? 0.8 * (sqrt(4 * self.k2 + power(self.k1, 2)) - self.k1) : undefined;
		return self;
	}
	static set_value = function(_value) {
		self.value = _value;
		self._lastX = _value;
		self.value_vel = 0;
		return self;
	}
	static get_value = function() {
		return self.value;
	}
	static update = function(_x, _time = 1, _x_vel = undefined) {
		if _time <= 0 return self.value;
		
		if (_x_vel == undefined) {
		    _x_vel = (_x - self._lastX) / _time;
		    self._lastX = _x;
		}
		if (self.accurate) {
		    var iterations = ceil(_time / self._crit);
		    _time = _time / iterations;
		    for (var i = 0; i < iterations; i++) {
			    self.value += self.value_vel * _time;
			    var value_accel = 
					(_x + self.k3 * _x_vel - self.value - self.k1 * self.value_vel) / self.k2 ;
				self.value_vel += _time * value_accel;
		    }
		} else {
		    self.value += self.value_vel * _time;
		    var newk2 = 
				max(self.k2, 1.1 * (_time * _time / 4 + _time * self.k1 / 2)) ;
			var value_accel = 
				(_x + self.k3 * _x_vel - self.value - self.k1 * self.value_vel) / newk2 ;
		    self.value_vel += _time * value_accel;
		}
		return self.value;
	}
}
