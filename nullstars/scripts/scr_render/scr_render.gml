
function Render() constructor {
	LOG(Log.Note, "Render(): initializing");
	
	/**
	@arg {struct.Root} _root
	*/
	static draw := function (_root) {
		shader_set(shd_tilemap);
		
		for (var i = 0; i < array_length(_root.world.rooms); i++) {
			var _room = _root.world.rooms[i];
			if _room.layer_graphic_front_vb != undefined {
				matrix_set(matrix_world, matrix_build(_room.x * TILE_SIZE, _room.y * TILE_SIZE, 0, 0, 0, 0, 1, 1, 1));
				vertex_submit(_room.layer_graphic_front_vb, pr_trianglelist, sprite_get_texture(_root.package.get_sprite_tiles(), 0));
			}
		}
		
		shader_reset();
		matrix_set(matrix_world, matrix_build_identity());
	};
}

