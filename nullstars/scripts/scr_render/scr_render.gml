
function Render() constructor {
	LOG(Log.Note, "Render(): initializing");
	
	/**
	@arg {struct.ns_Root} _root
	*/
	static draw := function (_root) {
		var _cam := nullstars_get_cam();
		
		shader_set(shd_tilemap);
		
		for (var i = 0; i < array_length(_root.world.rooms_list); i++) {
			var _room = _root.world.rooms_list[i];
			if _room.layer_graphic_front_vb != undefined {
				matrix_set(matrix_world, matrix_build(_room.x * (TILE_SIZE), _room.y * (TILE_SIZE), 0, 0, 0, 0, 1, 1, 1));
				vertex_submit(_room.layer_graphic_front_vb, pr_trianglelist, sprite_get_texture(_root.package.get_sprite_tiles(), 0));
			}
		}
		
		shader_reset();
		matrix_set(matrix_world, matrix_build_identity());
		
		with obj_game_Nova {
			draw_self();
		}
		
		with obj_game_Solid {
			draw_self();
		}
		
		for (var i = 0; i < array_length(_root.world.rooms_list); i++) {
			var _room = _root.world.rooms_list[i];
			
			var _color = c_white;
			
			if _room.target == ns_level_RoomTarget.Unload {
				_color := #444444;
			}
			else if _room.target == ns_level_RoomTarget.File {
				_color := c_red;
			}
			else if _room.target == ns_level_RoomTarget.Parse {
				_color := c_lime;
			}
			else if _room.target == ns_level_RoomTarget.Load {
				_color := c_blue;
			}
			else {
				ASSERT(false, $"???? {_room.target}");
			}
			
			draw_sprite_ext(spr_pixel, 0, _room.x + _cam.x, _room.y + _cam.y, _room.width, _room.height, 0, _color, 1);
		}
		
		draw_rectangle(
			_cam.x + _cam.x / TILE_SIZE,
			_cam.y + _cam.y / TILE_SIZE,
			_cam.x + _cam.x / TILE_SIZE + _cam.w / TILE_SIZE,
			_cam.y + _cam.y / TILE_SIZE + _cam.h / TILE_SIZE,
			true
		);
	};
}

