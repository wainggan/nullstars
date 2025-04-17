
enum Poll {
	Complete,
	// the Future is still running
	Running,
	// the Future is still running, but running poll()
	// again will *not* be able to advance it
	Wait,
}

function Future() constructor {
	static poll = function () {};
}

function FutureJoin(_a, _b) constructor {
	a = _a;
	b = _b;
	static poll = function () {
		if a != undefined {
			a.poll();
		}
		if b != undefined {
			b.poll();
		}
		if a == undefined && b == undefined {
			return Poll.Complete;
		} else {
			return Poll.Wait;
		}
	};
}

