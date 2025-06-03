
global.data_char = {
	cloth: {
		"none": undefined,
	},
	accessory: {
		"none": undefined,
	},
	ears: {
		
	},
	tail: {
		
	},
	color: {
		
	},
};

global.data_char_refs = {
	cloth: ["none"],
	accessory: ["none"],
	ears: [],
	tail: [],
	color: [],
};

/// @arg {string} _name
/// @arg {asset.GMSprite} _asset
function data_char_add_cloth(_name, _asset) {
	if global.data_char.cloth[$ _name] != undefined {
		LOG(Log.error, $"data_char.cloth: {_name} already exists");
	}
	global.data_char.cloth[$ _name] = _asset;
	array_push(global.data_char_refs.cloth, _name);
}

/// @arg {string} _name 
/// @arg {asset.GMSprite} _asset
function data_char_add_acc(_name, _asset) {
	if global.data_char.accessory[$ _name] != undefined {
		LOG(Log.error, $"data_char.accessory: {_name} already exists");
	}
	global.data_char.accessory[$ _name] = _asset;
	array_push(global.data_char_refs.accessory, _name);
}

/// @arg {string} _name 
/// @arg {enum.PlayerCharTail} _ref
function data_char_add_tail(_name, _ref) {
	if global.data_char.tail[$ _name] != undefined {
		LOG(Log.error, $"data_char.tail: {_name} already exists");
	}
	global.data_char.tail[$ _name] = _ref;
	array_push(global.data_char_refs.tail, _name);
}


/// @arg {string} _name 
/// @arg {array<real>} _color [eye color, 0 dashes, 1 dash, 2 dashes, etc...]
function data_char_add_color(_name, _color) {
	if global.data_char.color[$ _name] != undefined {
		LOG(Log.error, $"data_char.color: {_name} already exists");
	}
	global.data_char.color[$ _name] = _color;
	array_push(global.data_char_refs.color, _name);
}

data_char_add_cloth("shirt", spr_player_layer_shirt);
data_char_add_cloth("classic", spr_player_layer_shine);

data_char_add_acc("flower", spr_player_layer_flower);
data_char_add_acc("band", spr_player_layer_band);

data_char_add_tail("nova", PlayerCharTail.normal);
data_char_add_tail("fox", PlayerCharTail.fox);
data_char_add_tail("bunny", PlayerCharTail.bunny);
data_char_add_tail("dotted", PlayerCharTail.dots);
data_char_add_tail("fish", PlayerCharTail.hooked);
data_char_add_tail("split", PlayerCharTail.fork);
data_char_add_tail("halo", PlayerCharTail.halo);
data_char_add_tail("spine", PlayerCharTail.geared);

data_char_add_color("main", [ #ff00ff, #00ffff, #ff00ff ]);
data_char_add_color("hollow", [ #f27b3a, #965fe3, #f27b3a ]);
data_char_add_color("lush", [ #ca49f5, #e37f96, #26f059 ]);
data_char_add_color("gray", [ #777780, #1b1821, #c3c1e3 ]);


