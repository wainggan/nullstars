
global.data_char = {
	"none": undefined,
};

global.data_char_refs = {
	cloth: ["none"],
	accessory: ["none"],
};

/// @arg {string} _name
/// @arg {asset.GMSprite} _asset
function data_char_add_cloth(_name, _asset) {
	if global.data_char[$ _name] != undefined {
		LOG(Log.error, $"data_char.cloth: {_name} already exists");
	}
	global.data_char[$ _name] = _asset;
	array_push(global.data_char_refs.cloth, _name);
}

/// @arg {string} _name 
/// @arg {asset.GMSprite} _asset
function data_char_add_acc(_name, _asset) {
	if global.data_char[$ _name] != undefined {
		LOG(Log.error, $"data_char.accessory: {_name} already exists");
	}
	global.data_char[$ _name] = _asset;
	array_push(global.data_char_refs.accessory, _name);
}

data_char_add_cloth("shirt", spr_player_layer_shirt);
data_char_add_cloth("classic", spr_player_layer_shine);

data_char_add_acc("flower", spr_player_layer_flower);
data_char_add_acc("band", spr_player_layer_band);


