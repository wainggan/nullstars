
function Future() constructor {
	static poll = function (_wake) {
		return 0;
	};
}

function FutureJoin(_a, _b) constructor {
	a = _a;
	b = _b;
	static poll = function (_wake) {
		if a != undefined {
			var _out = a.poll(_wake);
			if _out != undefined {
				a = undefined;
			}
		}
		if b != undefined {
			var _out = b.poll(_wake);
			if _out != undefined {
				b = undefined;
			}
		}
		if a == undefined && b == undefined {
			return 0;
		} else {
			return undefined;
		}
	};
}

