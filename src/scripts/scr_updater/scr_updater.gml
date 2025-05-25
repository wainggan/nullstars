
function Variable(_default) {
	
	def = _default;
	value = def;
	priority = 0;
	
	static start = function() {
		value = def;
		priority = 0;
	};
	
	static set = function(_priority, _value) {
		if priority >= _priority return;
		priority = _priority;
		value = _value;
	};
	
	static edit = function(_priority, _callback) {
		self.set(_priority, _callback(value));
	};
	
}

function Updater() {
	
	variables = {};
	
	static add = function(_var) {
		array_push(variables, _var);
	}
	
	static start = function() {
		var _names = struct_get_names(variables);
		for (var i = 0; i < array_length(_names); i++) {
			variables[$ _names[i]].start();
		}
	}
	
	static edit = function(_name, _callback) {
		variables[$ _name].edit(_callback);
	}
	
}




