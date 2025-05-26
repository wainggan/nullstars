
if oo {
	if global.game.state.oo_onoff == polarity {
		collidable = true;
	} else {
		collidable = false;
	}
} else {
	if global.game.state.oo_updown == polarity {
		collidable = true;
	} else {
		collidable = false;
	}
}

