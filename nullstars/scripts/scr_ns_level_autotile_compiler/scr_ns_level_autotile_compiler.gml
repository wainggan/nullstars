function ns_level_autotile_tile_selection(_tilemap, _current, _x, _y) {
	var _tile := tilemap_get(_tilemap, _x, _y);
	if _tile == -1 {
		return _current;
	}
	if (_tile & 1) == 1 {
		return 0;
	}
	return _tile >> 2;
}

/**
converts a formatted json into (essentially) a faster-to-execute nested function (ns_level_AutotilePebis).
*/
function ns_level_AutotileCompiler() constructor {
	static compile := function (_json) {
		var _stamps := variable_struct_get(_json, "stamps");
		ASSERT(is_array(_stamps));
		
		var _rules := variable_struct_get(_json, "rules");
		ASSERT(is_array(_rules));
		
		var _pebis_stamps := {};
		
		for (var i = 0, _len := array_length(_stamps); i < _len; i++) {
			var _stamps_v := _stamps[i];
			
			var _stamps_id := variable_struct_get(_stamps_v, "id");
			ASSERT(is_string(_stamps_id));
			
			var _stamps_rule := variable_struct_get(_stamps_v, "rule");
			
			var _stamp := compile_stamp(_stamps_rule);
			
			_pebis_stamps[$ _stamps_id] := _stamp;
		}
		
		var _pebis_rules_array_len := array_length(_rules);
		
		var _pebis_rules_array := array_create(_pebis_rules_array_len);
		
		for (var i = 0; i < _pebis_rules_array_len; i++) {
			_pebis_rules_array[i] = compile_criteria(_rules[i]);
		}
		
		var _pebis_rules_root := method({
			array: _pebis_rules_array,
		}, ns_level_autotile_expr_criteria_list);
		
		return new ns_level_AutotilePebis(_pebis_stamps, _pebis_rules_root);
	};
	
	static compile_stamp := function (_json) {
		ASSERT(is_struct(_json));
		
		var _json_type := variable_struct_get(_json, "stamp");
		ASSERT(is_string(_json_type));
		
		switch _json_type {
			case "choose": {
				var _choose := variable_struct_get(_json, "choose");
				ASSERT(is_array(_choose));
				
				var _len := array_length(_choose);
				
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_stamp(_choose[i]);
				}
				
				return method({
					array: _array,
				}, ns_level_autotile_expr_stamp_choose);
			}
			
			case "list": {
				var _list := variable_struct_get(_json, "list");
				ASSERT(is_array(_list));
				
				var _len := array_length(_list);
				
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_stamp(_list[i]);
				}
				
				return method({
					array: _array,
				}, ns_level_autotile_expr_stamp_list);
			}
			
			case "tile": {
				var _src_x := variable_struct_get(_json, "src_x");
				ASSERT(is_real(_src_x));
				var _src_y := variable_struct_get(_json, "src_y");
				ASSERT(is_real(_src_y));
			
				var _off_x := variable_struct_get(_json, "off_x") ?? 0;
				ASSERT(is_real(_off_x));
			
				var _off_y := variable_struct_get(_json, "off_y") ?? 0;
				ASSERT(is_real(_off_y));
			
				var _off_z := variable_struct_get(_json, "off_z") ?? 0;
				ASSERT(is_real(_off_z));
			
				var _rand_x_min := variable_struct_get(_json, "rand_x_min") ?? 0;
				ASSERT(is_real(_rand_x_min));
			
				var _rand_x_max := variable_struct_get(_json, "rand_x_max") ?? 0;
				ASSERT(is_real(_rand_x_max));
			
				var _rand_y_min := variable_struct_get(_json, "rand_y_min") ?? 0;
				ASSERT(is_real(_rand_y_min));
			
				var _rand_y_max := variable_struct_get(_json, "rand_y_max") ?? 0;
				ASSERT(is_real(_rand_y_max));
				
				var _stamp := {
					src_x: _src_x,
					src_y: _src_y,
					
					off_x: _off_x,
					off_y: _off_y,
					off_z: _off_z,
					
					rand_x_min: _rand_x_min,
					rand_x_max: _rand_x_max,
					rand_y_min: _rand_y_min,
					rand_y_max: _rand_y_max,
				};
				
				return method({
					stamp: _stamp,
				}, ns_level_autotile_expr_stamp_tile);
			}
			
			default: {
				ASSERT(false, $"unknown type: {_json_type}");
			}
		}
	};
	
	static compile_condition := function (_json) {
		ASSERT(is_struct(_json));
		
		var _type := variable_struct_get(_json, "condition");
		ASSERT(is_string(_type));
		
		switch _type {
			case "all": {
				var _all := variable_struct_get(_json, "all");
				ASSERT(is_array(_all));
				
				var _len := array_length(_all);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_condition(_all[i]);
				}
				
				return method({
					array: _array,
				}, ns_level_autotile_expr_condition_all);
			}
			
			case "any": {
				var _any := variable_struct_get(_json, "any");
				ASSERT(is_array(_any));
				
				var _len := array_length(_any);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_condition(_any[i]);
				}
				
				return method({
					array: _array,
				}, ns_level_autotile_expr_condition_any);
			}
			
			case "none": {
				var _none := variable_struct_get(_json, "none");
				ASSERT(is_array(_none));
				
				var _len := array_length(_none);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_condition(_none[i]);
				}
				
				return method({
					array: _array,
				}, ns_level_autotile_expr_condition_none);
			}
			
			case "tileset": {
				var _tileset := variable_struct_get(_json, "tileset");
				ASSERT(is_array(_tileset));
				
				var _len := array_length(_tileset);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					var _value = _tileset[i];
					ASSERT(is_real(_value));
					_array[i] := _value;
				}
				
				return method({
					array: _array,
				}, ns_level_autotile_expr_condition_tileset);
			}
			
			case "class": {
				var _json_class := variable_struct_get(_json, "class");
				ASSERT(is_array(_json_class));
				
				var _len := array_length(_json_class);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					var _value = _json_class[i];
					ASSERT(is_real(_value));
					_array[i] := _value;
				}
				
				// is it a bad idea to name all of these "array"? yes.
				// is anyone going to stop me? unfortunately, no.
				return method({
					array: _array,
				}, ns_level_autotile_expr_condition_class);
			}
			
			case "noise": {
				var _threshold := variable_struct_get(_json, "threshold") ?? 0.5;
				ASSERT(is_real(_threshold));
				
				var _width := variable_struct_get(_json, "width") ?? 10;
				ASSERT(is_real(_width));
			
				var _height := variable_struct_get(_json, "height") ?? 10;
				ASSERT(is_real(_width));
				
				var _scale := variable_struct_get(_json, "scale") ?? 40;
				ASSERT(is_real(_scale));
				
				var _noise := ns_level_autotile_noise_generate(_width, _height);
			
				return method({
					noise: _noise,
					scale: _scale,
					threshold: _threshold,
				}, ns_level_autotile_expr_condition_noise);
			}
			
			default: {
				ASSERT(false, $"unknown type: {_type}");
			}
		}
	};
	
	static compile_criteria := function (_json) {
		ASSERT(is_struct(_json));

		var _json_type := variable_struct_get(_json, "rule");
		ASSERT(is_string(_json_type));
		
		switch _json_type {
			case "emit": {
				var _json_emit := variable_struct_get(_json, "emit");
				ASSERT(is_string(_json_emit));
				
				switch _json_emit {
					case "blob": {
						var _json_src_x := variable_struct_get(_json, "src_x");
						ASSERT(is_real(_json_src_x));
						
						var _json_src_y := variable_struct_get(_json, "src_y");
						ASSERT(is_real(_json_src_y));
						
						return method({
							src_x: _json_src_x,
							src_y: _json_src_y,
						}, ns_level_autotile_expr_criteria_emit_blob);
					}
					
					case "stamp": {
						var _json_stamp := variable_struct_get(_json, "stamp");
						ASSERT(is_string(_json_stamp));
						
						return method({
							stamp: _json_stamp,
						}, ns_level_autotile_expr_criteria_emit_stamp);
					}
					
					case "single": {
						var _json_single := variable_struct_get(_json, "single");
						
						var _stamp := compile_stamp(_json_single);
						
						return method({
							stamp: _stamp,
						}, ns_level_autotile_expr_criteria_emit_single)
					}
					
					default: {
						ASSERT(false, $"unknown emitter: {_json_emit}");
					}
				}
			}
			
			case "overlay": {
				var _json_overlay := variable_struct_get(_json, "overlay");
				
				var _overlay := compile_criteria(_json_overlay);
				
				var _json_with := variable_struct_get(_json, "with") ?? false;
				ASSERT(is_bool(_json_with));
				
				return method({
					overlay: _overlay,
					into: _json_with,
				}, ns_level_autotile_expr_criteria_overlay);
			}
			
			case "list": {
				var _json_list := variable_struct_get(_json, "list");
				ASSERT(is_array(_json_list));
				
				var _len := array_length(_json_list);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_criteria(_json_list[i]);
				}
				
				return method({
					array: _array,
				}, ns_level_autotile_expr_criteria_list);
			}
			
			case "choose": {
				var _json_choose := variable_struct_get(_json, "choose");
				ASSERT(is_array(_json_choose));
				
				var _len := array_length(_json_choose);
				var _array := array_create(_len);
				for (var i = 0; i < _len; i++) {
					_array[i] := compile_criteria(_json_choose[i]);
				}
				
				return method({
					array: _array,
				}, ns_level_autotile_expr_criteria_choose);
			}
			
			case "match": {
				var _json_match := variable_struct_get(_json, "match");
				
				var _match := compile_condition(_json_match);
				
				var _json_then := variable_struct_get(_json, "then");
				
				var _then := compile_criteria(_json_then);
				
				var _json_else := variable_struct_get(_json, "else");
				
				if _json_else != undefined {
					var _else := compile_criteria(_json_else);
					
					return method({
						match: _match,
						branch_then: _then,
						branch_else: _else,
					}, ns_level_autotile_expr_criteria_match_else);
				}
				else {
					return method({
						match: _match,
						branch_then: _then,
					}, ns_level_autotile_expr_criteria_match);
				}
			}
			
			default: {
				ASSERT(false, $"unknown type: {_json_type}");
			}
		}
	};
}

/**
global context for the autotile instructions.

@arg {struct} _stamps
@arg {function} _root
*/
function ns_level_AutotilePebis(_stamps, _root) constructor {
	stamps := _stamps;
	root := _root;
	
	tilemap = undefined;
	x = 0;
	y = 0;
	
	collector := new ns_level_StampCollector();
	
	/**
	
	
	@arg {id.Tilemap} _tilemap
	@arg {real} _x
	@arg {real} _y
	*/
	static run := function (_tilemap, _x, _y) {
		collector.clear();
		
		tilemap = _tilemap;
		x = _x;
		y = _y;
		
		root(self);
		
		return collector;
	};
}

/*
there are three types of nodes we are working with here:

stamp
	this describes what tiles to place down with what properties. they otherwise
	don't have any way of controlling anything but that basic declarative structure.
	their functions do not return anything.

criteria
	akin to control flow, this describes the shape of which the logic will flow.
	their functions return `true` to indicate that no further processing should occur.
	
condition
	akin to boolean operations, this allows for checking for various conditions within
	certain criteria.
	their functions return `true` if they match, and `false` if they don't.
*/

/**
internal. checks neighbors, and emits a matching tile.

@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_criteria_emit_blob(_root) {
	var _tilemap := _root.tilemap;
	var _x := _root.x;
	var _y := _root.y;
	
	var _current := tilemap_get(_tilemap, _x, _y) >> 2;
	
	var _topleft :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x - 1, _y - 1);
	var _top :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x, _y - 1);
	var _topright :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x + 1, _y - 1);
	var _left :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x - 1, _y);
	var _right :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x + 1, _y);
	var _bottomleft :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x - 1, _y + 1);
	var _bottom :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x, _y + 1);
	var _bottomright :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x + 1, _y + 1);
	
	var _t_i := ns_level_autotile_neighbor_to_neighbor_index(
		_topleft != 0,
		_top != 0,
		_topright != 0,
		_left != 0,
		_right != 0,
		_bottomleft != 0,
		_bottom != 0,
		_bottomright != 0
	);
	
	var _t_s := ns_level_autotile_lut_neighbor_index_to_blob_offset_index()[_t_i];
	
	var _t_t := ns_level_autotile_lut_offset_index_to_offset_position(_t_s);
	
	_root.collector.add(src_x + _t_t.x, src_y + _t_t.y);
	
	return true;
}

/**
internal. emits the attached stamp.

@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_criteria_emit_single(_root) {
	stamp(_root);
	
	return true;
}

/**
internal. emits the attached stamp reference.

@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_criteria_emit_stamp(_root) {
	// todo: pre-resolve this call
	_root.stamps[$ stamp](_root)
	
	return true;
}

/**
internal. if the condition is true, evaluate the attached branch.

@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_criteria_match(_root) {
	if match(_root) {
		return branch_then(_root);
	}
}

/**
internal. if the condition is true, evaluate the attached branch. otherwise, evaluate the attached else-branch.

@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_criteria_match_else(_root) {
	if match(_root) {
		return branch_then(_root);
	}
	else {
		return branch_else(_root);
	}
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_criteria_list(_root) {
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if array[i](_root) {
			return true;
		}
	}
	return false;
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_criteria_choose(_root) {
	var _len := array_length(array);
	if _len != 0 {
		return array[irandom(_len - 1)](_root);
	}
	return false;
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_criteria_overlay(_root) {
	overlay(_root);
	return into;
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_condition_all(_root) {
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if !array[i](_root) {
			return false;
		}
	}
	return true;
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_condition_any(_root) {
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if array[i](_root) {
			return true;
		}
	}
	return false;
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_condition_none(_root) {
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if array[i](_root) {
			return false;
		}
	}
	return true;
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_condition_class(_root) {
	var _tilemap := _root.tilemap;
	var _x := _root.x;
	var _y := _root.y;
	
	var _current := tilemap_get(_tilemap, _x, _y) >> 2;
	
	var _topleft :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x - 1, _y - 1);
	var _top :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x, _y - 1);
	var _topright :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x + 1, _y - 1);
	var _left :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x - 1, _y);
	var _right :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x + 1, _y);
	var _bottomleft :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x - 1, _y + 1);
	var _bottom :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x, _y + 1);
	var _bottomright :=
		ns_level_autotile_tile_selection(_tilemap, _current, _x + 1, _y + 1);
	
	var _t_i := ns_level_autotile_neighbor_to_neighbor_index(
		_topleft != 0,
		_top != 0,
		_topright != 0,
		_left != 0,
		_right != 0,
		_bottomleft != 0,
		_bottom != 0,
		_bottomright != 0
	);
	
	var _t_s := ns_level_autotile_lut_neighbor_index_to_blob_resolved_offset_index()[_t_i];
	
	// show_debug_message("{0} {1} {2} {3}", _t_s, _t_i, _current, array);
	
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if array[i] == _t_s {
			return true;
		}
	}
	
	return false;
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_condition_tileset(_root) {
	var _current := tilemap_get(_root.tilemap, _root.x, _root.y) >> 2;

	for (var i = 0, _len := array_length(array); i < _len; i++) {
		if array[i] == _current {
			return true;
		}
	}
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_condition_noise(_root) {
	var _noise := noise;
	var _noise_grid := noise.data;
	var _noise_w := _noise.width;
	var _noise_h := _noise.height;
	
	var _x_s := _root.x * _noise_w / scale % _noise_w;
	var _y_s := _root.y * _noise_h / scale % _noise_h;
	
	var _x_m := _x_s % 1;
	var _y_m := _y_s % 1;
	
	var _x_0 := floor(_x_s);
	var _x_1 := ceil(_x_s) % _noise_w;
	var _y_0 := floor(_y_s);
	var _y_1 := ceil(_y_s) % _noise_h;
	
	var _r_00 := _noise_grid[_x_0 + _y_0 * _noise_w];
	var _r_10 := _noise_grid[_x_1 + _y_0 * _noise_w];
	var _r_01 := _noise_grid[_x_0 + _y_1 * _noise_w];
	var _r_11 := _noise_grid[_x_1 + _y_1 * _noise_w];
	
	var _r_x0 := _r_00 * (1 - _x_m) + _r_10 * _x_m;
	var _r_x1 := _r_01 * (1 - _x_m) + _r_11 * _x_m;
	var _r_xy := _r_x0 * (1 - _y_m) + _r_x1 * _y_m;
	
	return _r_xy > threshold;
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_stamp_choose(_root) {
	var _len := array_length(array);
	if _len != 0 {
		array[irandom(_len - 1)](_root);
	}
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_stamp_list(_root) {
	for (var i = 0, _len := array_length(array); i < _len; i++) {
		array[i](_root);
	}
}

/**
@arg {struct.ns_level_AutotilePebis} _root
*/
function ns_level_autotile_expr_stamp_tile(_root) {
	_root.collector.add(
		stamp.src_x,
		stamp.src_y,
		stamp.off_x,
		stamp.off_y,
		stamp.off_z,
		stamp.rand_x_min,
		stamp.rand_x_max,
		stamp.rand_y_min,
		stamp.rand_y_max
	);
}

/**
array optimization. caches struct creation.
*/
function ns_level_StampCollector() constructor {
	array := [];
	length = 0;
	
	static clear := function () {
		length = 0;
	};
	
	static add := function (
		_src_x,
		_src_y,
		_off_x = 0,
		_off_y = 0,
		_off_z = 0,
		_rand_x_min = 0,
		_rand_x_max = 0,
		_rand_y_min = 0,
		_rand_y_max = 0,
	) {
		if array_length(array) == length {
			array_push(array, {
				src_x: 0,
				src_y: 0,
				
				off_x: 0,
				off_y: 0,
				off_z: 0,
				
				rand_x_min: 0,
				rand_x_max: 0,
				rand_y_min: 0,
				rand_y_max: 0,
			});
		}
		
		var _cache := array[length++];
		
		_cache.src_x = _src_x;
		_cache.src_y = _src_y;
		
		_cache.off_x = _off_x;
		_cache.off_y = _off_y;
		_cache.off_z = _off_z;
		
		_cache.rand_x_min = _rand_x_min;
		_cache.rand_x_max = _rand_x_max;
		_cache.rand_y_min = _rand_y_min;
		_cache.rand_y_max = _rand_y_max;
	};
}

/**
@arg {real} _width
@arg {real} _height
@arg {real} [_seed]
*/
function ns_level_autotile_noise_generate(_width, _height, _seed = undefined) {
	var _length := _width * _height;
	var _array := array_create(_length);
	
	var _seed_prev;
	if _seed != undefined {
		_seed_prev := random_get_seed();
		// random_set_seed(_seed, true);
	}
	
	for (var i = 0; i < _length; i++) {
		_array[i] = random(1);
	}
	
	if _seed != undefined {
		// random_set_seed(_seed_prev, true);
	}
	
	return {
		data: _array,
		width: _width,
		height: _height,
	};
}



/**
used to convert neighbor tile data into an 8-bit number.
each bit corresponds to a neighbor.

the corner bits (`_topleft`, `_bottomleft`, `_bottomright`, `_topright`) are
zeroed if either of their respective corresponding sides are `false`.

@arg {bool} _topleft 0th bit
@arg {bool} _top 1st bit
@arg {bool} _topright 2nd bit
@arg {bool} _left 3rd bit
@arg {bool} _right 4th bit
@arg {bool} _bottomleft 5th bit
@arg {bool} _bottom 6th bit
@arg {bool} _bottomright 7th bit
*/
function ns_level_autotile_neighbor_to_neighbor_index(_topleft, _top, _topright, _left, _right, _bottomleft, _bottom, _bottomright) {
	if !_left || !_top {
		_topleft = false;
	}
	if !_left || !_bottom {
		_bottomleft = false;
	}
	if !_right || !_top {
		_topright = false;
	}
	if !_right || !_bottom {
		_bottomright = false;
	}
	
	var _index =
		(+_topleft) +
		(+_top << 1) +
		(+_topright << 2) +
		(+_left << 3) +
		(+_right << 4) +
		(+_bottomleft << 5) +
		(+_bottom << 6) +
		(+_bottomright << 7);
	
	return _index;
}


