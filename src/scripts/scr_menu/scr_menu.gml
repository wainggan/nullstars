
function Menu() constructor {
	
	stack = []
	
	static open = function(_page){
		_page.init();
		array_push(stack, _page);
		return self;
	}
	
	static update = function(){
		
		if array_length(stack) == 0 return;
		
		var _stack = array_last(stack);
		_stack.update(self);
		
	}
	
	static close = function(){
		array_pop(stack)
	}
	
	static stop = function(){
		while array_length(stack)
			close();
	}
	
}


function MenuPage() constructor {
	
	anim = 0;
	
	// run once when added to Menu()
	static init = function(){};
	
	// run if input is available to the player
	static update = function(){};
	
	// run every frame on draw
	static draw = function(){};
	
}

function MenuPageList(_width = 200) : MenuPage() constructor {
	
	list = [];
	current = 0;
	width = _width;
	
	anim_desc = 0;
	
	static init = function() {
		anim = 0;
		anim_desc = 0;
		current = 0;
	}
	
	static update = function(_menu) {
		
		var _kh = 
			INPUT.check_stutter("right", 8, 4) -
			INPUT.check_stutter("left", 8, 4);
			
		var _kv = 
			INPUT.check_stutter("down", 8, 5) -
			INPUT.check_stutter("up", 8, 5);
			
		var _click = INPUT.check_pressed("jump");
		var _close = INPUT.check_pressed("dash");
		
		current = mod_euclidean(current + _kv, array_length(list));
		
		if _click || _kh != 0 {
			list[current].input(_click, _kh < 0, _kh > 0);
			return;
		}
		
		if _close {
			_menu.close();
		}
		
	}
	
	static add = function(_item) {
		array_push(list, _item);
		return self;
	}
	
	static draw = function(_x, _y, _active) {
		
		anim = approach(anim, _active, 1 / 10);
		
		if anim == 0 return;
		
		var _scale = global.settings.graphic.textscale + 1;
		
		var _width = width * _scale;
		var _height = 200 * _scale;
		
		var _width_t = 160 * _scale;
		
		var _pad_x = 8 * _scale;
		var _pad_y = 11 * _scale;
		var _option_pad = 14 * _scale;
		
		draw_set_font(ft_sign);
		draw_set_color(#cccccc);
		
		_x = clamp(_x, 16, WIDTH - (_width + _width_t) - 16);
		_y = clamp(_y, 16, HEIGHT - _height - 16);
		
		var _active_desc = list[current].description != undefined;
		anim_desc = approach(anim_desc, _active_desc, 1 / 10)
		if anim_desc != 0 {
			draw_sprite_stretched(
				spr_sign_board, 0,
				_x + _width - 8, _y + 8,
				_width_t * tween(Tween.Circ, anim_desc),
				_height - 16
			);
			
			if anim_desc >= 1 {
				draw_text_ext_transformed(
					_x + _width - 8 + 4 + _pad_x,
					_y + 8 + _pad_y,
					list[current].description,
					-1, (_width_t - 8 - 8) / _scale - _pad_x,
					_scale, _scale, 0
				);
			}
		}
		
		draw_sprite_stretched(
			spr_sign_board, 0,
			_x, _y,
			_width, _height * tween(Tween.Circ, anim)
		);
		
		if anim < 1 return;
		
		for (var j = 0; j < array_length(list); j++) {
			var _e = list[j]
			if j == current
				draw_text_transformed(
					_x + _pad_x,
					_y + _pad_y + j * _option_pad,
					">",
					_scale, _scale, 0
				);
			_e.draw(
				_x + _pad_x + 12 * _scale,
				_y + _pad_y + j * _option_pad,
				_x + _width - _pad_x * 2,
				j == current,
			);
		}
		
		draw_set_color(c_white);
		
	}
	
}

function MenuPageMap() : MenuPage() constructor {
	
	cam_x = 0;
	cam_y = 0;
	cam_scale = 1 / 24;
	
	static init = function() {
		anim = 0;
		cam_x = obj_player.x;
		cam_y = obj_player.y;
	}
	
	static update = function(_menu) {
		
		var _kh = INPUT.check("right") - INPUT.check("left");
		var _kv = INPUT.check("down") - INPUT.check("up");
		
		var _speed = INPUT.check("grab");
		var _click = INPUT.check_pressed("jump");
		var _close = INPUT.check_pressed("dash");
		
		
		var _dir = point_direction(0, 0, _kh, _kv);
		var _spd = _speed ? 6 : 3;
	
		if _kh != 0 || _kv != 0 {
			cam_x += lengthdir_x(_spd / cam_scale, _dir);
			cam_y += lengthdir_y(_spd / cam_scale, _dir);
		}
		
		var _c = noone;
		with obj_checkpoint {
			var _c_dist = point_distance(other.cam_x, other.cam_y, x, y);
			var _c_dir = point_direction(other.cam_x, other.cam_y, x, y);

			if _c_dist < 16 / other.cam_scale {
				other.cam_x = approach(other.cam_x, x, abs(lengthdir_x(1 / other.cam_scale, _c_dir)));
				other.cam_y = approach(other.cam_y, y, abs(lengthdir_y(1 / other.cam_scale, _c_dir)));
				_c = self;
				break;
			}
		}
		
		if _click && _c != noone {
			_menu.stop();
		
			game_checkpoint_set_index(_c.index);
			
			global.game.add_timeline(new Timeline().add(new KeyframeRespawn()));
		
			return;
		}
		
		if _close {
			_menu.close();
			return;
		}
		
	}
	
	static draw = function(_x, _y, _active) {
		
		anim = approach(anim, _active, 1 / 14);
		
		if anim == 0 return;
		
		var _cam = game_camera_get();
		
		var _pos_x = 0 + WIDTH / 2;
		var _pos_y = 0 + HEIGHT / 2;
		var _pos_w = 400 * hermite(anim);
		var _pos_h = 300 * hermite(anim);

		var _pos_xoff = _pos_x - _pos_w / 2;
		var _pos_yoff = _pos_y - _pos_h / 2;
		
		var _cam_x = round(cam_x);
		var _cam_y = round(cam_y);

		draw_sprite_stretched_ext(spr_map_background, 0, _pos_xoff, _pos_yoff, _pos_w, _pos_h, c_black, 1);
		
		var _pad = 16 * 8;
		
		for (var i = 0; i < array_length(global.game.level.levels); i++) {
			var _lvl = global.game.level.levels[i];
			var _c_x = (_lvl.x - _pad - _cam_x) * cam_scale;
			var _c_y = (_lvl.y - _pad - _cam_y) * cam_scale;
			var _c_w = (_lvl.width + _pad * 2) * cam_scale;
			var _c_h = (_lvl.height + _pad * 2) * cam_scale;
			
			var _col = #666666;
			
			// @todo: currently, the Loader() level data struct
			// does not keep track of any fields, which makes this
			// invalid. make this work pls
			//switch game_level_grab_data(_lvl).area {
				//case "hub":
					//_col = #777788;
					//break;
				//case "area0":
					//_col = #009999;
					//break;
				//case "area1":
					//_col = #996699;
					//break;
			//}
			
			draw_sprite_ext(
				spr_pixel, 0,
				WIDTH / 2 + _c_x, HEIGHT/ 2 + _c_y, _c_w, _c_h * hermite(anim),
				0, _col, 1
			);
		}
	
		with obj_checkpoint {
			var _c_x = (x - _cam_x) * (other.cam_scale);
			var _c_y = (y - _cam_y) * (other.cam_scale);
			var _dist = point_distance(0, 0, _c_x, _c_y);
			var _dir = point_direction(0, 0, _c_x, _c_y);
		
			_c_x += lengthdir_x(WIDTH * 0.5 * hermite(1 - other.anim), _dir);
			_c_y += lengthdir_y(HEIGHT * 0.5 * hermite(1 - other.anim), _dir);
		
			draw_sprite_ext(
				spr_player_tail, 0,
				WIDTH / 2 + 0 + _c_x,
				HEIGHT / 2 + 0 + _c_y,
				tween(Tween.Circ, other.anim),
				tween(Tween.Circ, other.anim),
				0, c_white, 1
			);
		}
	
		draw_sprite(spr_debug_marker, 0, 0 + WIDTH / 2, 0 + HEIGHT / 2);
	
	}

}

function MenuPageChar(_kind) : MenuPage() constructor {
	kind = _kind;
	current = 0;
	anim_current = 0;
	list = undefined;
	
	static tail = new PlayerTail();
	
	static init = function () {
		anim = 0;
		
		if kind == 0 {
			list = global.data_char_refs.cloth;
			current = array_get_index(list, global.data.player.cloth);
		} else if kind == 1 {
			list = global.data_char_refs.accessory;
			current = array_get_index(list, global.data.player.accessory);
		} else if kind == 2 {
			list = global.data_char_refs.ears;
			current = array_get_index(list, global.data.player.ears);
		} else if kind == 3 {
			list = global.data_char_refs.tail;
			current = array_get_index(list, global.data.player.tail);
		} else if kind == 4 {
			list = global.data_char_refs.color;
			current = array_get_index(list, global.data.player.color);
		} else {
			ASSERT(false);
		}
		
		anim_current = current;
	};
	
	static update = function (_menu) {
		
		var _kh = 
			INPUT.check_stutter("right", 8, 4) -
			INPUT.check_stutter("left", 8, 4);
			
		var _kv = 
			INPUT.check_stutter("down", 8, 5) -
			INPUT.check_stutter("up", 8, 5);
			
		var _click = INPUT.check_pressed("jump");
		var _close = INPUT.check_pressed("dash");
		
		current = mod_euclidean(current + _kh, array_length(list));
		
		if _click {
			LOG(Log.note, $"MenuPageChar(): selected {current}");
			if kind == 0 {
				global.data.player.cloth = list[current];
			} else if kind == 1 {
				global.data.player.accessory = list[current];
			} else if kind == 2 {
				global.data.player.ears = list[current];
			} else if kind == 3 {
				global.data.player.tail = list[current];
			} else if kind == 4 {
				global.data.player.color = list[current];
			} else {
				ASSERT(false);
			}
			game_file_save();
			return;
		}
		
		if _close {
			_menu.close();
		}
		
	};
	
	static draw = function (_x, _y, _active) {
		
		anim = approach(anim, _active, 1 / 10);
		
		var _w = 512 * tween(Tween.Circ, anim);
		var _h = 320 * tween(Tween.Circ, anim);
		
		draw_sprite_stretched(
			spr_sign_board, 0,
			WIDTH / 2 - _w / 2, HEIGHT / 2 - _h / 2,
			_w, _h
		);
		
		if anim < 1 {
			return;
		}
		
		anim_current = lerp(anim_current, current, 0.6);
		
		var _tail = list == global.data_char_refs.tail ? list[current] : global.data.player.tail;
		var _color = list == global.data_char_refs.color ? list[current] : global.data.player.color;
		tail.update(0, 0, 1, 0, _tail);
		
		static __mat_scale = matrix_build(WIDTH / 2, HEIGHT / 2, 0, 0, 0, 0, 2, 2, 1);
		matrix_set(matrix_world, __mat_scale);
		
		tail.draw(1, _tail, _color, c_white);
		
		static __mat_ident = matrix_build_identity();
		matrix_set(matrix_world, __mat_ident);
		
		
		draw_player(
			0,
			WIDTH / 2,
			HEIGHT / 2 + 32,
			2, 2,
			0, c_white,
			list == global.data_char_refs.cloth ? "none" : global.data.player.cloth,
			list == global.data_char_refs.accessory ? "none" : global.data.player.accessory,
			list == global.data_char_refs.ears ? "none" : global.data.player.ears,
			_color
		);
		
		draw_set_halign(fa_center);
		
		for (var i = 0; i < array_length(list); i++) {
			var _item = list[i];
			
			var _asset = undefined;
			var _check = false;
			if kind == 0 {
				_asset = global.data_char.cloth[$ _item];
				_check = _check || _item == global.data.player.cloth;
			} else if kind == 1 {
				_asset = global.data_char.accessory[$ _item];
				_check = _check || _item == global.data.player.accessory;
			} else if kind == 2 {
				_asset = global.data_char.ears[$ _item];
				_check = _check || _item == global.data.player.ears;
			} else if kind == 3 {
				//_asset = global.data_char.tail[$ _item];
				_check = _check || _item == global.data.player.tail;
			} else if kind == 4 {
				//_asset = global.data_char.color[$ _item];
				_check = _check || _item == global.data.player.color;
			} else {
				ASSERT(false);
			}
			
			var _xx = WIDTH / 2 + (i - anim_current) * 64;
			if _asset == undefined {
				draw_circle_outline(_xx, HEIGHT / 2, 6, 1, c_white, clamp(abs(i - anim_current), 0, 1), 12);
				draw_text(_xx, HEIGHT / 2 + 48, _item);
			} else {
				draw_sprite_ext(_asset, 0, _xx, HEIGHT / 2 + 32, 2, 2, 0, c_white, 1);
				draw_text(_xx, HEIGHT / 2 + 48, _item);
			}
			
			if _check {
				var _width = string_width(_item);
				draw_line_sprite(_xx - _width / 2, HEIGHT / 2 + 48 + 9, _xx + _width / 2, HEIGHT / 2 + 48 + 9, 1, #ffffff, 1);
			}
		}
		
		draw_set_halign(fa_left);
		
	};
}

function MenuOption() constructor {
	
	static __none = function(){}
	
	callback = __none;
	input = __none;
	description = undefined;
	
	static draw = function(_x, _y){
		draw_text(_x, _y, "- empty -")
	}
	
}

function MenuButton(
		_text, _callback = __none,
		_description = undefined
	) : MenuOption() constructor {
	
	text = _text;
	callback = _callback;
	description = _description;
	
	input = function(_click, _left, _right){
		if _click callback();
	}
	
	static draw = function(_x1, _y, _x2, _selected){
		var _last = draw_get_color()
		if _selected draw_set_color(c_white);
		
		var _scale = global.settings.graphic.textscale + 1;
		draw_text_transformed(_x1, _y, text, _scale, _scale, 0);
		
		if _selected draw_set_color(_last);
	}
	
}

function MenuSlider(
		_text,
		_min = 0, _max = 1,
		_iter = 0.1, _value = 0,
		_callback = __none,
		_description = undefined
	) : MenuOption() constructor {
	
	text = _text;
	
	low = _min;
	high = _max;
	iter = _iter;
	value = _value;
	
	callback = _callback;
	description = _description;
	
	input = function(_click, _left, _right) {
		value = clamp(value + (_right - _left) * iter, low, high);
		callback(value);
	}
	
	static draw = function(_x1, _y, _x2, _selected) {
		var _last = draw_get_color()
		if _selected draw_set_color(c_white);
		
		var _scale = global.settings.graphic.textscale + 1;
		
		draw_text_transformed(_x1, _y, text, _scale, _scale, 0);
		
		var _xm = (_x2 - _x1) / 2; // middle point

		draw_line_sprite(_x1 + _xm, _y, _x2, _y, _scale);
		
		var _p = _xm + _xm * (abs(value - low) / abs(high - low))
		draw_circle_sprite(_x1 + _p, _y + 1, 4, c_white, 1);
		
		if _selected draw_set_color(_last);
	}
	
}

function MenuRadio(
		_text,
		_options = [], _value = 0,
		_callback = __none,
		_description = undefined
	) : MenuOption() constructor {
	
	text = _text;
	
	options = _options;
	value = _value;
	
	callback = _callback;
	description = _description;
	
	input = function(_click, _left, _right) {
		value = mod_euclidean(value + (_right - _left), array_length(options));
		callback(value);
	}
	
	static draw = function(_x1, _y, _x2, _selected) {
		var _last = draw_get_color()
		if _selected draw_set_color(c_white);
		
		var _scale = global.settings.graphic.textscale + 1;
		
		draw_text_transformed(_x1, _y, text, _scale, _scale, 0);
		
		var _off = 0;
		
		draw_set_halign(fa_right)
		for (var i = array_length(options) - 1; i >= 0; i--) {
			
			draw_text_transformed(_x2 - _off, _y, options[i], _scale, _scale, 0);
			
			if value == i
				draw_line_sprite(
					_x2 - _off - string_width(options[i]) * _scale - 3,
					_y + 10 * _scale,
					_x2 - _off,
					_y + 10 * _scale,
					_scale,
				);
			
			_off += (string_width(options[i]) + 14) * _scale;
			
		}
		draw_set_halign(fa_left)
		
		if _selected draw_set_color(_last);
	}
	
}

