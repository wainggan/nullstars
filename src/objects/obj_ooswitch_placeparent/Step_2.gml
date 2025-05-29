
if game_paused() exit;

hit_buffer -= 1;
anim_hit = approach(anim_hit, 0, 0.15);

var _inst = instance_place(x, y, obj_Actor);
if _inst != noone && array_contains(target, _inst.object_index) {
	
	if !hit && !hit_buffer {
		game_set_pause(4);
	
		if oo == 0 {
			global.game.state.oo_onoff = !global.game.state.oo_onoff;
		} else {
			global.game.state.oo_updown = !global.game.state.oo_updown;
		}
		
		
		anim_hit = 1;
		
		if _inst.object_index == obj_player with _inst {
			dash_left = defs.dash_total;
		}
	}
	hit = true;
	hit_buffer = 12;
	
} else {
	hit = false;
}


