#[derive(Debug, serde::Deserialize)]
struct TiledMap {
	/// in tiles
	width: i32,
	/// in tiles
	height: i32,
	layers: Vec<TiledLayer>,
	tilesets: Vec<TiledTileset>,
}

#[derive(Debug, serde::Deserialize)]
struct TiledLayer {
	id: i64,
	name: String,
	#[serde(flatten)]
	type_: TiledLayerType,
}

#[derive(Debug, serde::Deserialize)]
#[serde(tag = "type")]
enum TiledLayerType {
	#[serde(rename = "tilelayer")]
	Tilelayer {
		width: i32,
		height: i32,
		data: Vec<u32>,
	},
	#[serde(rename = "objectgroup")]
	Objectgroup {
		objects: Vec<TiledObject>,
	},
}

#[derive(Debug, serde::Deserialize)]
struct TiledObject {
	id: i64,
	name: String,
	x: f64,
	y: f64,
	width: f64,
	height: f64,
	properties: Option<Vec<TiledProperty>>,
}

#[derive(Debug, serde::Deserialize)]
struct TiledProperty {
	name: String,
	#[serde(rename = "type")]
	type_: TilePropertyType,
	propertytype: String,
	value: serde_json::Value,
}

#[derive(Debug, serde::Deserialize)]
#[serde(rename_all = "lowercase")]
enum TilePropertyType {
	String,
	Int,
	Float,
	Bool,
	Color,
	File,
	Object,
	Class,
}

#[derive(Debug, serde::Deserialize)]
struct TiledTileset {
	firstgid: i32,
	source: String,
}

#[derive(Debug, Default)]
enum Cli {
	#[default] None,
	Room(CliRoom),
}


#[derive(Debug, Default)]
struct CliRoom {
	input: Option<String>,
	output: Option<String>,
}

const COMMAND: purcarg::Command<Cli, ()> = purcarg::Command::new()
	.name(&[b"nsconv"])
	.subcommand(&[
		purcarg::Command::new()
			.name(&[b"room"])
			.action_layer(|_, _| {
				Ok(Cli::Room(CliRoom::default()))
			})
			.argument(&[
				purcarg::Argument::new()
					.positional(b"input")
					.action_layer(|mut layer, next| {
						match layer {
							Cli::Room(ref mut room) => {
								room.input = next()
									.map(|x| str::from_utf8(x))
									.transpose()
									.map_err(|_| ())?
									.map(|x| x.to_string());
							}
							_ => unreachable!(),
						}
						Ok(layer)
					}),
				purcarg::Argument::new()
					.positional(b"output")
					.action_layer(|mut layer, next| {
						match layer {
							Cli::Room(ref mut room) => {
								room.output = next()
									.map(|x| str::from_utf8(x))
									.transpose()
									.map_err(|_| ())?
									.map(|x| x.to_string());
							}
							_ => unreachable!(),
						}
						Ok(layer)
					}),
			]),
	]);

const CONFIG: purcarg::Config = purcarg::Config::new();

const OUTPUT: purcarg::Output = purcarg::Output::new();

fn main() {
	let cli = purcarg::parse_bytes(
		OUTPUT,
		CONFIG,
		COMMAND,
		argv::iter()
			.map(|x| x.as_encoded_bytes())
			.skip(1),
		Cli::default(),
	).unwrap();

	let cli = match cli {
		purcarg::Success::Help | purcarg::Success::Version => return,
		purcarg::Success::Layer(cli) => cli,
	};

	match cli {
		Cli::None => {
			eprintln!("no action specified.");
		}

		Cli::Room(cli_room) => {
			let Some(input) = cli_room.input
				else {
					eprintln!("missing input");
					return;
				};

			let Some(output) = cli_room.output
				else {
					eprintln!("missing output");
					return;
				};

			let input_file =
				match std::fs::read_to_string(input) {
					Ok(ok) => ok,
					Err(error) => {
						eprintln!("error reading file: {error}");
						return;
					}
				};

			let json = serde_json::from_str::<TiledMap>(&input_file).unwrap();

			println!("meow {:?}", json);

			let mut tiles = Vec::new();

			let json_tiles = json.layers
				.iter()
				.find(|x| x.name == "Solid")
				.and_then(|x| match x.type_ {
					TiledLayerType::Tilelayer {
						width,
						height,
						ref data,
					} => Some((width, height, data)),
					_ => None,
				})
				.unwrap();

			let tileset_solid = json.tilesets
				.iter()
				.find(|x| x.source.ends_with("solid.tsx"))
				.unwrap();

			let tileset_semisolid = json.tilesets
				.iter()
				.find(|x| x.source.ends_with("semisolid.tsx"))
				.unwrap();

			let tileset_spike = json.tilesets
				.iter()
				.find(|x| x.source.ends_with("spike.tsx"))
				.unwrap();

			let tilesets = [
				(0, tileset_solid.firstgid),
				(1, tileset_semisolid.firstgid),
				(2, tileset_spike.firstgid),
			];

			for tile in json_tiles.2.iter().copied() {
				let Some(tileset) = tilesets
					.iter()
					.fold(
						None,
						|acc, x| {
							if x.1.cast_unsigned() <= tile {
								Some(x)
							}
							else {
								acc
							}
						})
				else {
					tiles.push(nullstars_nsfs::RoomTile::Empty);
					continue;
				};

				let index = u8::try_from(
					tile.strict_sub(tileset.1.cast_unsigned())
				).unwrap();

				if tileset.0 == 0 {
					tiles.push(nullstars_nsfs::RoomTile::Solid(index));
				}
				else if tileset.0 == 1 {
					tiles.push(nullstars_nsfs::RoomTile::Semisolid(
						nullstars_nsfs::Direction::from_index(index)
					));
				}
				else if tileset.0 == 2 {
					tiles.push(nullstars_nsfs::RoomTile::Spike(
						nullstars_nsfs::Direction::from_index(index)
					));
				}
				else {
					unreachable!();
				}
			}

			let room = nullstars_nsfs::Room {
				x_offset: 0,
				y_offset: 0,
				width: json.width.cast_unsigned(),
				height: json.height.cast_unsigned(),
				tiles,
				entities: Vec::new(),
			};

			let bin = nullstars_nsfs::pack_room(&room);

			match std::fs::write(&output, bin) {
				Ok(_) => (),
				Err(error) => {
					eprintln!("error writing file: {error}");
				}
			}
		}
	}
}
