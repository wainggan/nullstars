
global.data_music = {};
global.data_music_refs = {};

function data_music_add(_asset, _ref, _meta) {
	if global.data_music[$ _asset] != undefined {
		LOG(Log.error, $"data_music: ${_asset} already exists!");
	}
	
	static __fn = function (_a, _name, _value) {
		if !variable_struct_exists(_a, _name) {
			_a[$ _name] = _value;
		}
	};
	
	__fn(_meta, "name", "");
	__fn(_meta, "artist", "");
	__fn(_meta, "description", "");
	__fn(_meta, "bpm", 60);

	global.data_music[$ _asset] = _meta;
	global.data_music_refs[$ _ref] = _asset;
}

data_music_add(nameof(mus_wind), "wind", {});
data_music_add(nameof(mus_questionthestars), "stars", {
	name: "Love Letter",
	artist: "parchment",
	bpm: 130,
});
data_music_add(nameof(mus_yearsago), "lava", {
	name: "Skies and Nightmares",
	artist: "parchment",
	bpm: 124,
});
data_music_add(nameof(mus_hub_1), "hub", {
	name: "Glass Against Stone",
	artist: "parchment",
	bpm: 136,
});
data_music_add(nameof(mus_story), "story", {
	name: "Incipit",
	artist: "parchment",
	bpm: 134,
});
data_music_add(nameof(mus_inekstasis), "ekstasis", {
	name: "In Ekstasis",
	artist: "parchment",
	bpm: 110,
});

