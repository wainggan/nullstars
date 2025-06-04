
global.data_music = {};
global.data_music_refs = {};

function data_music_add(_asset = "", _name = "", _ref = "", _artist = "", _description = "") {
	if global.data_music[$ _asset] != undefined {
		LOG(Log.error, $"data_music: ${_asset} already exists!");
	}
	global.data_music[$ _asset] = {
		name: _name,
		description: _description,
		artist: _artist,
	};
	global.data_music_refs[$ _ref] = _asset;
}

data_music_add(nameof(mus_wind), "wind", "wind", "", "");
data_music_add(nameof(mus_questionthestars), "Love Letter", "stars", "parchment", "");
data_music_add(nameof(mus_yearsago), "Skies and Nightmares", "lava", "parchment", "");
data_music_add(nameof(mus_hub_1), "Glass Against Stone", "hub", "parchment", "");
data_music_add(nameof(mus_story), "Incipit", "story", "parchment", "");

