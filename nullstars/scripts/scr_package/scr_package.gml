
/**
the main keeper and processor of resources.
*/
function Package(_name) constructor {
	LOG(Log.Note, $"Package(): initializing on '{_name}'");
	
	directory := _name == undefined ? "base" : $"mods/{_name}";
	
	LOG(Log.Note, $"Package(): reading in '{directory}'");
	
	if !directory_exists(directory) {
		throw $"package '{_name}' does not exist";
	}
	
	var _path_package = $"{directory}/package.json";
	
	LOG(Log.Note, $"Package(): loading from '{_path_package}'");
	package := nullstars_file_json_load(_path_package);
	if package == -1 {
		throw $"package '{_name}' missing package.json";
	}
	
	LOG(Log.Note, "Package(): loaded package.json");
	
	// todo: package.json validation
	
	var _path_sprite_tiles := $"{directory}/tiles.png";
	
	LOG(Log.Note, $"Package(): loading from '{_path_sprite_tiles}'");
	sprite_tiles := sprite_add(_path_sprite_tiles, 0, false, false, 0, 0);
	ASSERT(sprite_exists(sprite_tiles));
	
	sprite_tiles_uvs := undefined;
	
	static destoy := function () {
		sprite_delete(texture_tiles);
	};
	
	static load_world_root := function () {
		var _path = $"{directory}/world/root.nsw";
		LOG(Log.Note, $"Package(): loading '{_path}'")
		var _buffer = buffer_load(_path);
		if _buffer == -1 {
			LOG(Log.Warn, $"Package(): '{_path}' returned -1")
		}
		return _buffer;
	};
	
	/**
	@arg {string} _id
	*/
	static load_world_room := function (_id) {
		var _buffer = buffer_load($"{directory}/world/{_id}.nsm");
		return _buffer;
	};
	
	static get_pkg_name := function () {
		ASSERT(is_string(package.name));
		return package.name;
	};
	
	static get_pkg_version := function () {
		ASSERT(is_real(package.version));
		return package.version;
	};
	
	static get_pkg_description := function () {
		ASSERT(is_string(package.description));
		return package.description;
	};
	
	static get_sprite_tiles := function () {
		return sprite_tiles;
	};
	
	static get_sprite_tiles_uvs := function () {
		if sprite_tiles_uvs == undefined {
			var _uvs := sprite_get_uvs(sprite_tiles, 0);
			
			sprite_tiles_uvs := {
				left: _uvs[0],
				top: _uvs[1],
				right: _uvs[2],
				bottom: _uvs[3],
			};
		}
		
		return sprite_tiles_uvs;
	};
}

