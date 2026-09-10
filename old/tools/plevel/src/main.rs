
use notify::EventKind;
use pack::Pack;
use std::ffi::OsStr;
use std::path::PathBuf;
use std::fs;

mod types;
mod make;
mod pack;

fn run(file_input: PathBuf, path_output: PathBuf) -> Result<(), String> {

	let is_main = file_input.extension() == Some(OsStr::new("ldtk"));
	let is_room = file_input.extension() == Some(OsStr::new("ldtkl"));

	let json_file = fs::read(&file_input)
		.map_err(|e| format!(
			"file \"{}\" doesn't exist: {}",
			&file_input.to_str().unwrap_or("err"), e
		))?;
	let json_str = std::str::from_utf8(&json_file)
		.map_err(|e| format!("invalid utf8: {}", e))?;

	let mut file_output;
	let buffer;

	if is_main {
		let json: types::LdtkJson = serde_json::from_str(json_str)
			.map_err(|e| format!("invalid json: {}", e))?;

		let makes = make::make_main(&json);
		buffer = makes.pack_new();

		file_output = path_output.clone();
		file_output.push("world.bin");
	} else if is_room {
		let json: types::Level = serde_json::from_str(json_str)
			.map_err(|e| format!("invalid json: {}", e))?;

		let makes = make::make_room(&json);
		buffer = makes.pack_new();

		file_output = path_output.clone();
		file_output.push("room");

		if !fs::exists(&file_output).unwrap_or(false) {
			fs::create_dir(&file_output).unwrap();
		}
		
		let name_src = file_input.clone();
		let name = name_src
			.file_stem()
			.unwrap_or(OsStr::new("err"))
			.to_str().unwrap_or("err");

		file_output.push(format!("{}.bin", name));
	} else {
		return Err(format!("what the fuck?"));
	}

	println!(
		"{} -> {}",
		file_input.to_str().unwrap_or("err"),
		file_output.to_str().unwrap_or("err"),
	);

	std::fs::write(&file_output, buffer)
		.map_err(|e| format!(
			"error writing to \"{}\": {}",
			&file_output.to_str().unwrap_or("<>"), e
		))?;

	// println!("complete! in {}ms", tt_time.elapsed().as_millis());
	// println!("json {} kb => bin {} kb ;3", tt_total_json / 1024, tt_total_bin / 1024);

	Ok(())
}

fn main() {
	let args: Vec<String> = std::env::args().collect();

	if args.len() < 3 {
		panic!("expected 2 parameters");
	}

	let path_input = PathBuf::from(&args[1]);
	let path_output = PathBuf::from(&args[2]);

	println!("watching {:?}", path_input);

	let (tx, rx) = std::sync::mpsc::channel::<notify::Result<notify::Event>>();

	let mut watcher = notify::recommended_watcher(tx).unwrap();

	use notify::Watcher;
	watcher.watch(&path_input, notify::RecursiveMode::Recursive).unwrap();

	for res in rx {
		match res {
			Ok(event) => {

				if let EventKind::Modify(_) = event.kind {
					for p in event.paths {
						if p.is_dir() {
							continue;
						}
						run(p, path_output.clone()).unwrap_or_else(|e| eprintln!("{}", e));
					}
				}
				
			},
			Err(e) => println!("watch error: {:?}", e),
		}
	}

}

