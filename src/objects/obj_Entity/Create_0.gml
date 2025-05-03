
event_inherited();

/*
 * object representing something that can meaningfully
 * do literally anything
 * 
 * see `scr_entity`
 */

collidable = true;

// runs when the scene "resets".
// the object should return to the same state it was
// initialized.
reset = function(){};

// camera offset
/// @arg {struct.Camera} _out
cam = function(_out) {
	_out.move(x, y)
}

