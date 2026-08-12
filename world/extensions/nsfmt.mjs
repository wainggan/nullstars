/*
# nsfmt

tiled extension for exporting tiled files to nullstars map data.

## usage

### tilemap



*/

const config = {
	version_world: 0,
	version_room: 0,
	magic_nullstars: "nullstars",
	magic_world: "W",
	magic_room: "R",
	tile_size: 16,
	world_export_property_name: "__nsfmt_exportdefault",
};

class Writer {
	constructor(file) {
		this.file = file;

		this.__array_8_buf = new ArrayBuffer(1);
		this.__array_8_view = new DataView(this.__array_8_buf);

		this.__array_16_buf = new ArrayBuffer(2);
		this.__array_16_view = new DataView(this.__array_16_buf);

		this.__array_32_buf = new ArrayBuffer(4);
		this.__array_32_view = new DataView(this.__array_32_buf);

		this.__array_64_buf = new ArrayBuffer(8);
		this.__array_64_view = new DataView(this.__array_64_buf);
	}

	fill_u8(value) {
		this.__array_8_view.setUint8(0, value);
		return this.__array_8_buf;
	}

	fill_i8(value) {
		this.__array_8_view.setInt8(0, value);
		return this.__array_8_buf;
	}

	u8(value) {
		this.file.write(this.fill_u8(value));
	}

	i8(value) {
		this.file.write(this.fill_i8(value));
	}

	fill_u16(value) {
		this.__array_16_view.setUint16(0, value, true);
		return this.__array_16_buf;
	}

	fill_i16(value) {
		this.__array_16_view.setInt16(0, value, true);
		return this.__array_16_buf;
	}

	u16(value) {
		this.file.write(this.fill_u16(value));
	}

	i16(value) {
		this.file.write(this.fill_i16(value));
	}

	fill_u32(value) {
		this.__array_32_view.setUint32(0, value, true);
		return this.__array_32_buf;
	}

	u32(value) {
		this.file.write(this.fill_u32(value));
	}

	i32(value) {
		this.file.write(this.fill_i32(value));
	}

	fill_i32(value) {
		this.__array_32_view.setInt32(0, value, true);
		return this.__array_32_buf;
	}

	fill_u64(value) {
		this.__array_64_view.setUint64(0, value, true);
		return this.__array_64_buf;
	}

	fill_i64(value) {
		this.__array_64_view.setInt64(0, value, true);
		return this.__array_64_buf;
	}

	u64(value) {
		this.file.write(this.fill_u64(value));
	}

	i64(value) {
		this.file.write(this.fill_i64(value));
	}

	fill_string(value) {
		const buf = new ArrayBuffer(value.length + 1);
		const view = new Uint8Array(buf);

		for (let i = 0; i < value.length; i++) {
			view[i] = value.charCodeAt(i);
		}

		view[view.length - 1] = 0;
		return buf;
	}

	string(value) {
		this.file.write(this.fill_string(value));
	}

	buffer(value) {
		this.file.write(value);
	}
};

const action_world_compile_fn = () => {
	if (tiled.worlds.length === 0) {
		tiled.error("no world is currently loaded.", () => {});
		return;
	}

	const project = tiled.project;
	const projectpath = FileInfo.path(tiled.projectFilePath);

	let filename = project.property(config.world_export_property_name);
	if (filename === undefined) {
		filename = FileInfo.relativePath(projectpath, tiled.promptSaveFile());
		project.setProperty(config.world_export_property_name, filename);
	}

	if (!FileInfo.isAbsolutePath(filename)) {
		filename = FileInfo.joinPaths(projectpath, filename);
		filename = FileInfo.cleanPath(filename);
	}

	const world = tiled.worlds[0];

	const filepath = tiled.filePath(filename);

	const file = new BinaryFile(filename, BinaryFile.WriteOnly);

	const writer = new Writer(file);

	writer.string(config.magic_nullstars);
	writer.string(config.magic_world);

	writer.u16(config.version_world);

	const maps = world.allMaps();

	writer.u32(maps.length);

	for (const map of maps) {
		writer.string(FileInfo.baseName(map.fileName));
		writer.i32(map.rect.x / config.tile_size | 0);
		writer.i32(map.rect.y / config.tile_size | 0);
		writer.i32(map.rect.width / config.tile_size | 0);
		writer.i32(map.rect.height / config.tile_size | 0);
	}

	file.commit();
};

const action_world_compile = tiled.registerAction("nsfmt_world_compile", action_world_compile_fn);
action_world_compile.text = "world compiler";
// action_world_compile.checkable = true;

if (tiled.menus.includes("File")) {
	tiled.extendMenu("File", [
		{
			action: "nsfmt_world_compile",
			before: "Close",
		},
		{
			separator: true,
		},
	]);
}

tiled.registerMapFormat("nsmap", {
	name: "nullstars map format",
	extension: "nsm",
	write: (map, filename) => {
		const file = new BinaryFile(filename, BinaryFile.WriteOnly);

		const writer = new Writer(file);

		writer.string(config.magic_nullstars);
		writer.string(config.magic_room);

		writer.u16(config.version_room);

		const width = map.width;
		const height = map.height;

		writer.u32(width);
		writer.u32(height);

		const layers = map.layers;

		let layer_solid;
		let layer_entity;

		for (const layer of layers) {
			if (layer.name === "Solid" && layer.isTileLayer) {
				layer_solid = layer;
				continue;
			}

			if (layer.name === "Entity" && layer.isObjectLayer) {
				layer_entity = layer;
				continue;
			}
		}

		if (layer_solid === undefined) {
			const msg = "no tile layer named 'Solid'";
			tiled.error(msg, () => {});
			throw new Error(msg);
		}

		if (layer_entity === undefined) {
			const msg = "no object layer named 'Entity'";
			tiled.error(msg, () => {});
			throw new Error(msg);
		}

		writer.u32(width * height);

		const solid_buffer = new ArrayBuffer(width * height);
		const solid_view = new Uint8Array(solid_buffer);

		for (let y = 0; y < height; y++) {
			for (let x = 0; x < width; x++) {
				const i = x + y * width;

				const tile = layer_solid.tileAt(x, y);
				if (tile === null) {
					continue;
				}

				const tileset = tile.tileset;

				const type = tileset.resolvedProperty("type");
				if (type === undefined) {
					tiled.error(`tileset '${tileset.name}' missing type`, () => {});
					return;
				}

				const id = tile.id;

				if (id >= 0b0011_1111) {
					tiled.error(`tile @ ${x} ${y} has id=${id}`);
					return;
				}

				const value = type.value;

				if (value === 0) {
					// solids
					solid_view[i] = (tile.id + 1) | 0b0000_0000;
				}
				else if (value === 1) {
					// spikes
					solid_view[i] = tile.id | 0b0100_0000;
				}
				else if (value === 2) {
					// semisolids
					solid_view[i] = tile.id | 0b1000_0000;
				}
				else {
					tiled.error(`unknown solid type ${value}`, () => {});
					return;
				}
			}
		}

		writer.buffer(solid_buffer);

		const objects = layer_entity.objects;

		writer.u32(objects.length);

		for (let i = 0; i < objects.length; i++) {
			const obj = objects[i];

			writer.string(obj.name);
			writer.i32(obj.x);
			writer.i32(obj.y);
		}

		file.commit();
	},
});

