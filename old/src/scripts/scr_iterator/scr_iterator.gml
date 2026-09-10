
function Iterator() constructor {
	static next = function () {
		static __out = {
			value: undefined,
			done: false,
		};
		return __out;
	};
	
	static collect = function (_array = []) {
		var _temp = self.next();
		while !_temp.done {
			array_push(_array, _temp.value);
			_temp = self.next();
		}
		return _array;
	};
	
	static filter = function (_fn) {
		return new IteratorFilter(self, _fn);
	};
	
	static map = function (_fn) {
		return new IteratorMap(self, _fn);
	};
}

/// @arg {struct} _iter
function IteratorFrom(_iter) : Iterator() constructor {
	ASSERT(_iter.next != undefined);
	iter = _iter;
	static next = function () {
		return iter.next();
	};
}

/// @arg {struct.Iterator} _iter
/// @arg {function} _fn
function IteratorFilter(_iter, _fn) : Iterator() constructor {
	ASSERT(_iter.next != undefined);
	
	iter = _iter;
	fn = _fn;
	
	static next = function () {
		var _temp = iter.next();
		while !_temp.done && !fn(_temp.value) {
			_temp = iter.next();
		}
		return _temp;
	};
}

/// @arg {struct.Iterator} _iter
/// @arg {function} _fn
function IteratorMap(_iter, _fn) : Iterator() constructor {
	ASSERT(_iter.next != undefined);
	
	iter = _iter;
	fn = _fn;
	
	static next = function () {
		var _temp = iter.next();
		_temp.value = fn(_temp.value);
		return _temp;
	};
}

/// @arg {array} _array
/// @return {struct.Iterator}
function array_iter(_array) {
	return new IteratorFrom({
		array: _array,
		i: 0,
		next: function () {
			static __out = {
				value: undefined,
				done: false,
			};
			
			__out.value = array[i];
			
			if i + 1 < array_length(array) {
				__out.done = false;
				i++;
			} else {
				__out.done = true;
			}
			
			return __out;
		},
	});
}

/// @arg {real} _from
/// @arg {real | undefined} _to
function iter_range(_from, _to) {
	ASSERT(_to >= _from);
	return new IteratorFrom({
		n: _from,
		m: _to,
		next: function () {
			static __out = {
				value: undefined,
				done: false,
			};
			
			if m == undefined {
				__out.value = n++;
				__out.done = false;
				return __out;
			}
			
			__out.value = n;
			
			if n + 1 < m {
				__out.done = false;
				n++;
			} else {
				__out.done = true;
			}
			
			return __out;
		},
	});
}

/// @arg {struct} _iter
/// @return {struct.Iterator}
function iter_from(_iter) {
	return new IteratorFrom(_iter);
}

