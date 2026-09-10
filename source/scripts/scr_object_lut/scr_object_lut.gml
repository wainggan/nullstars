function ns_object_lut_info() {
	static __out := {
		obj_game_Nova: {
			ref: "Nova",
			sort: 0,
		},
	};
	
	return __out;
}

function ns_object_lut_name() {
	static __out = undefined;
	
	if __out == undefined {
		var _info := ns_object_lut_info();
		var _info_names := struct_get_names(_info);
		
		__out := {};
		
		for (var i = 0, _len := array_length(_info_names); i < _len; i++) {
			var _info_name := _info_names[i];
			var _info_item := _info[$ _info_name];
			__out[$ _info_item.ref] := asset_get_index(_info_name);
		}
	}
	
	return __out;
}

