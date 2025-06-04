
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
		if array_contains(game_level_get_flags(global.game.camera.x, global.game.camera.y), "hub") {
			_bgm_ref = "hub";
		}
	
		switch _bgm_ref {
			case undefined:
				_bgm_ref = bgm_ref;
				break;
			case "none":
				_bgm_ref = undefined;
				break;
			default:
				//var _asset = global.data_music_refs[$ _bgm];
				//_bgm_asset = asset_get_index(_asset);
				// _bgm_name = global.data_music[$ _asset].name;
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
		
		var _meta = global.data_music[$ global.data_music_refs[$ bgm_ref]];
		bpm += _meta.bpm / 60;
		if bpm >= 1 {
			bpm -= 1;
			bpm_frame = true;
		} else {
			bpm_frame = false;
		}
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
			var _meta = global.data_music[$ global.data_music_refs[$ bgm_ref]];
			LOG(Log.user, $"playing: {_meta.name} - {_meta.artist}");
		}
	})
	.set("step", function() {
		if bgm_ref == undefined {
			bgm_ref = bgm_ref_next;
			if bgm_ref != undefined {
				var _asset = asset_get_index(global.data_music_refs[$ bgm_ref]);
				bgm = audio_play_sound(_asset, 0, true, 0);
				if bgm_old[$ _asset] != undefined {
					audio_sound_set_track_position(bgm, bgm_old[$ _asset]);
				}
			}
			state.change(state_idle);
		} else if audio_sound_get_gain(bgm) == 0 {
			var _asset = asset_get_index(global.data_music_refs[$ bgm_ref]);
			bgm_old[$ _asset] = audio_sound_get_track_position(bgm);
			audio_stop_sound(bgm);
			bgm_ref = bgm_ref_next;
			if bgm_ref != undefined {
				var _asset_new = asset_get_index(global.data_music_refs[$ bgm_ref]);
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
	return global.data_music[$ global.data_music_refs[$ global.game.music.bgm_ref]];
}
/// @return {real}
function game_music_get_bpm() {
	return game_music_get_data().bpm;
}
/// @return {real}
function game_music_get_beat() {
	return global.game.music.bpm;
}
/// @return {bool}
function game_music_get_beat_frame() {
	return global.game.music.bpm_frame;
}

