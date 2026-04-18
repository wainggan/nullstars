/*
generic state machine.
*/

/**
create a new, empty state machine.
*/
function calico_create() {
	return new __Calico();
}

/**
changes the machine's current state. if the machine is running, this
will not take effect until the event is complete. otherwise, the state
will change immediately.

@arg {struct.__Calico} _machine
@arg {string} _state
*/
function calico_change(_machine, _state) {
	_machine.__change(_state);
}

/**
runs an event.
do not run this while the machine is running.

@arg {struct.__Calico} _machine
@arg {string} _event
*/
function calico_run(_machine, _event) {
	_machine.__run(_event, 0);
}

/**
delegates to the current running state's child state.
should only be run inside an event.

@arg {struct.__Calico} _machine
*/
function calico_child(_machine) {
	_machine.__child();
}

/**
confirm a state's current state.

@arg {struct.__Calico} _machine
@arg {string} _state
*/
function calico_is(_machine, _state) {
	return _machine.__current == _state;
}

/**
set a machine's current state, without triggering onenter/onleave.

@arg {struct.__Calico} _machine
@arg {string} _state
*/
function calico_mut_current(_machine, _state) {
	_machine.__current = _state;
}

/**
create a new, empty state.

@arg {struct.__Calico} _machine
@arg {string} _state
@arg {string} [_parent]
*/
function calico_mut_new(_machine, _state, _parent = undefined) {
	_machine.__add_state(_state, _parent);
}

/**
set a state's onenter function.

@arg {struct.__Calico} _machine
@arg {string} _state
@arg {function, undefined} _callback
*/
function calico_mut_onenter(_machine, _state, _callback) {
	_machine.__states[$ _state].onenter = _callback;
}

/**
set a state's onleave function.

@arg {struct.__Calico} _machine
@arg {string} _state
@arg {function, undefined} _callback
*/
function calico_mut_onenter(_machine, _state, _callback) {
	_machine.__states[$ _state].onleave = _callback;
}

/// @ignore
function __Calico() constructor {
	// map of available states.
	/// @ignore
	__states := {};
	
	// current state. indexes into `__states`.
	/// @ignore
	__current = undefined;
	
	// used to tell when the machine is running, which is good for invariant checking
	// when `__running` is true, `__running_name` and `__running_type` are set to
	// the current event name and type. that way when child() is called by the user,
	// it can automatically run the correct event (as the user context doesn't have access
	// to the currently running event anyways).
	/// @ignore
	__running = false;
	/// @ignore
	__running_name = undefined;
	/// @ignore
	__running_type = 0;
	
	// when the user calls change() while running, it would be a bad idea to actually change
	// the current state there (it is, counter-intuitively, unintuitive behaviour). instead,
	// this gets set, and when running is complete, the machine can call change() automatically.
	/// @ignore
	__defer = undefined;
	
	// cache.
	// this avoids having to constantly create arrays.
	/// @ignore
	__cache_current = undefined;
	/// @ignore
	__cache_tree_list := [];
	/// @ignore
	__cache_tree_index = 0;
	
	// run an event.
	/// @ignore
	static __run := function (_event, _type) {
		if __current == undefined {
			// the current state isn't even initialized...
			return;
		}
		
		// this would be really bad to allow.
		ASSERT(!__running, $"cannot call run() while state machine is running");
		
		ASSERT_EQ(__defer, undefined, $"uh oh?");
		
		// from the current event, generate a list of 'dependencies'.
		
		if __cache_current != __current {
			array_resize(__cache_tree_list, 0);
			__cache_tree_index = 0;
		
			var _check = __current;
			while _check != undefined {
				array_push(__cache_tree_list, __states[$ _check]);
				_check = __states[$ _check].parent;
			}
			
			__cache_current = __current;
		}
		
		// set flag stating that we are running.
		
		__running = true;
		__running_name = _event;
		__running_type = _type;
		
		// yippee
		__child(_event, _type);
		
		__running = false;
		
		// if event changed, change it :3
		if __defer != undefined {
			// this dance ensures that the earlier assertion passes.
			var _defer = __defer;
			__defer = undefined;
			__change(_defer);
		}
	};
	
	/// @ignore
	static __change := function (_state) {
		if !__running {
			__run(__current, 2);
			__current = _state;
			__run(__current, 1);
		}
		else {
			__defer = _state;
		}
	};
	
	/// @ignore
	static __child := function (_event = __running_name, _type = __running_type) {
		ASSERT(__running, $"cannot call child() when state machine isn't running");
		
		// "pop"
		__cache_tree_index -= 1;
		
		if __cache_tree_index >= 0 {
			var _callback;
			
			var _state := __cache_tree_list[__cache_tree_index];
			
			if _type == 0 {
				_callback := _state.events[$ _event];
			}
			else if _type == 1 {
				_callback := _state.onenter;
			}
			else if _type == 2 {
				_callback := _state.onleave;
			}
			else {
				ASSERT(false, $"type '{_type}' invalid");
			}
			
			if _callback != undefined {
				_callback(self);
			}
			else {
				// automatically delegate if not set.
				__child(_event, _type);
			}
		}
		
		// "push"
		__cache_tree_index += 1;
	};
	
	/// @ignore
	static __add_state := function (_state, _parent) {
		__states[$ _state] := {
			parent: _parent,
			onleave: undefined,
			onenter: undefined,
			events: {},
		};
	};
}


