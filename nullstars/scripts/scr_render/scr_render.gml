
function Render() constructor {
	LOG(Log.Note, "Render(): initializing");
	
	/**
	@arg {struct.ns_Root} _root
	*/
	static draw := function (_root) {
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
	};
}

