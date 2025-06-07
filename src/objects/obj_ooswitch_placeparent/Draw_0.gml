
var _index = 1;
if oo == 0 {
	_index += global.game.state.oo_onoff ? 1 : 0;
	light.color = !global.game.state.oo_onoff ? #ddffff : #ffddff;
} else {
	_index += 2 + (global.game.state.oo_updown ? 1 : 0);
	light.color = global.game.state.oo_updown ? #ffffdd : #eeddff;
}

draw_sprite(sprite_index, _index, x, y);

