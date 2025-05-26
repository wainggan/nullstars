

function game_player_kill() {
	if !instance_exists(obj_player) {
		return;
	}
	
	var _x = obj_player.x, _y = obj_player.y;
	
	game_render_particle(_x, _y - 16, ps_player_death_0);
	
	game_sound_play(sfx_death);
	
	game_set_pause(14);
	game_camera_set_shake(2, 0.4);
	
	game_timer_stop();
	
	instance_destroy(obj_player);
	
	global.game.add_timeline(
		new Timeline()
			.add(new KeyframeTimed(2))
			.add(new KeyframeCallback(method({ _x, _y }, function(){
				game_render_particle(_x, _y - 16, ps_player_death_1);
				game_camera_set_shake(8, 0.8);
				game_set_pause(1);
				game_render_wave(_x, _y - 16, 256, 90, 1, spr_wave_wave);
				
				with obj_Entity {
					reset();
				}
				global.onoff = 1;
			})))
			.add(new KeyframeTimed(10))
			.add(new KeyframeRespawn().set_pos(_x, _y))
	);
}

