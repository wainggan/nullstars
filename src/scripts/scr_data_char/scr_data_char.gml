
global.data_char = {
	cloth: [undefined],
	accessory: [undefined],
};

function data_char_add_cloth(_asset, _name = "") {
	array_push(global.data_char.cloth, {
		asset: _asset,
		name: _name,
	});
}

function data_char_add_acc(_asset, _name = "") {
	array_push(global.data_char.cloth, {
		asset: _asset,
		name: _name,
	});
}

data_char_add_cloth(spr_player_layer_shirt, "shirt");

data_char_add_acc(spr_player_layer_flower, "flower");


