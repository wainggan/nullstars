
if respawn_timer > 0 {
	var _prog = min(tween(Tween.MidSlow, respawn_timer / 16), 1) / 2;
	draw_circle_outline_part(x, y - 20, 32, 6, _prog, 90, false, c_white, 1, 24);
	draw_circle_outline_part(x, y - 20, 32, 6, _prog, 90, true, c_white, 1, 24);
}

if self.fn_get_menu() != undefined && !self.state.is(self.state_menu) {
	anim_menu = approach(anim_menu, 1, 0.1);
} else {
	anim_menu = approach(anim_menu, 0, 0.1);
}

if anim_menu > 0 {
	var _width = 20 * tween(Tween.Circ, anim_menu);
	var _height = 20 * tween(Tween.Ease, anim_menu);
	draw_sprite_stretched(spr_sign_board, 0, x - _width / 2, bbox_top - 16 - _width, _width, _height);
	if anim_menu == 1 {
		draw_sprite(spr_sign_emark, 0, x, bbox_top - 16 - 5);
	}
}

