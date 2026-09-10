
function Music() constructor {
		
	bgm = -1;
	
	bgm_ref = undefined;
	bgm_ref_last = undefined
	bgm_ref_next = undefined
	
	bgm_old = {};
	
	bpm = 0;
	bpm_frame = false;
	
	
	state = new State();
	
	state_base = state.add();
	state_base.set("step", function() {
		
		var _bgm_ref = game_level_get_music(global.game.camera.x, global.game.camera.y);

		switch _bgm_ref {
			case undefined:
				_bgm_ref = bgm_ref;
				break;
			case "none":
				_bgm_ref = undefined;
				break;
			default:
				break;
		}
		
		if state.is(state_idle) {
			if _bgm_ref != bgm_ref {
				// really wish this was calico ...
				bgm_ref_next = _bgm_ref;
				state.change(state_switch);
			}
		} else {
			if _bgm_ref == bgm_ref {
				// feels like a bad idea
				state.change(state_idle);
			}
		}
		
		state.child();
		
		bgm_ref_last = _bgm_ref;
		
		var _bpm = 60;
		if bgm_ref != undefined {
			_bpm = global.meta_data.music[$ bgm_ref][$ nameof(bpm)] ?? 60;
		}
		
		bpm += _bpm / 60 / 60;
	});
	
	state_idle = state_base.add();
	
	state_switch = state_base.add()
	.set("enter", function() {
		if bgm_ref != undefined {
			audio_sound_gain(bgm, 0, 2000);
		}
	})
	.set("leave", function() {
		if bgm_ref != undefined {
			audio_sound_gain(bgm, game_sound_get_bgm(), 2000);
			var _meta = global.meta_data.music[$ bgm_ref];
			var _meta_name = _meta[$ nameof(name)] ?? "";
			var _meta_artist = _meta[$ nameof(artist)] ?? "";
			LOG(Log.user, $"playing: {_meta_name} - {_meta_artist}");
		}
	})
	.set("step", function() {
		if bgm_ref == undefined {
			bgm_ref = bgm_ref_next;
			if bgm_ref != undefined {
				var _asset = asset_get_index(global.meta_data.music[$ bgm_ref].asset);
				bgm = audio_play_sound(_asset, 0, true, 0);
				if bgm_old[$ _asset] != undefined {
					audio_sound_set_track_position(bgm, bgm_old[$ _asset]);
				}
			}
			state.change(state_idle);
		} else if audio_sound_get_gain(bgm) == 0 {
			var _asset = asset_get_index(global.meta_data.music[$ bgm_ref].asset);
			bgm_old[$ _asset] = audio_sound_get_track_position(bgm);
			audio_stop_sound(bgm);
			bgm_ref = bgm_ref_next;
			if bgm_ref != undefined {
				var _asset_new = asset_get_index(global.meta_data.music[$ bgm_ref].asset);
				bgm = audio_play_sound(_asset_new, 0, true, 0);
				if bgm_old[$ _asset_new] != undefined {
					audio_sound_set_track_position(bgm, bgm_old[$ _asset_new]);
				}
			}
			state.change(state_idle);
		}
	})
	
	state.change(state_idle);
	
	// @todo: this is technically bad
	global.game.news_sound.subscribe(function () {
		if audio_exists(bgm) && state.is(state_idle) {
			audio_sound_gain(bgm, game_sound_get_bgm(), 50);
		}
	});
	
	static update = function () {
		state.run();
	};

}

function game_music_get_data() {
	return global.meta_data.music[$ bgm_ref];//global.data_music[$ global.data_music_refs[$ global.game.music.bgm_ref]];
}
/// @return {real}
function game_music_get_bpm() {
	return game_music_get_data().bpm;
}
/// @return {real}
function game_music_get_beat(_part = 1) {
	return (global.game.music.bpm * (1 / _part)) % 1;
}
/// @return {real}
function game_music_get_beat_tri(_part = 1) {
	return 2 * abs(game_music_get_beat(_part) - 0.5);
}
/// @return {real}
function game_music_get_beat_lead(_part = 1) {
	return max(0, 2 * (-game_music_get_beat(_part) + 0.5));
}
/// @return {real}
function game_music_get_beat_invlead(_part = 1) {
	return max(0, 2 * (game_music_get_beat(_part) - 0.5));
}
/// @return {bool}
function game_music_get_beat_now() {
	return global.game.music.bpm_frame;
}

