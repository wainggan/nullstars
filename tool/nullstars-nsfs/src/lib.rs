#![doc = include_str!("../readme.md")]

#![warn(clippy::pedantic)]

const MAGIC_TAG: &str = "nullstars";
const MAGIC_WORLD: &str = "W";
const MAGIC_ROOM: &str = "R";
const VERSION_WORLD: u16 = 0;
const VERSION_ROOM: u16 = 0;

pub struct World {
	/// list of rooms
	pub rooms: Vec<WorldRoom>,
}

pub struct WorldRoom {
	/// room id
	pub name: String,
	/// x position in tiles
	pub x: i32,
	/// y position in tiles
	pub y: i32,
	/// width of room in tiles
	pub width: u32,
	/// height of room in tiles
	pub height: u32,
}

pub struct Room {
	/// room x offset in tiles
	pub x_offset: i32,
	/// room y offset in tiles
	pub y_offset: i32,
	/// width of room in tiles
	pub width: u32,
	/// height of room in tiles
	pub height: u32,
	/// 'solid' tiles.
	pub tiles: Vec<RoomTile>,
	pub entities: Vec<Entity>,
}

pub struct Entity {
	pub name: String,
	pub x: i32,
	pub y: i32,
}

impl Room {
	#[must_use]
	pub fn tile_get(&self, x: usize, y: usize) -> Option<&RoomTile> {
		const {
			assert!(usize::BITS >= u32::BITS);
		}
		let i = x + y * self.width as usize;
		if i >= self.tiles.len() {
			None
		}
		else {
			Some(&self.tiles[i])
		}
	}

	#[must_use]
	pub fn tile_get_mut(&mut self, x: usize, y: usize) -> Option<&mut RoomTile> {
		const {
			assert!(usize::BITS >= u32::BITS);
		}
		let i = x + y * self.width as usize;
		if i >= self.tiles.len() {
			None
		}
		else {
			Some(&mut self.tiles[i])
		}
	}
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum RoomTile {
	Empty,
	Solid(u8),
	Semisolid(Direction),
	Spike(Direction),
}

impl RoomTile {
	pub fn from_raw(index: u8) -> Self {
		if index == 0 {
			RoomTile::Empty
		}
		else {
			let mask = index & 0b1100_0000;
			if mask == 0b0100_0000 {
				RoomTile::Spike(Direction::from_index(index & 0b0000_0011))
			}
			else if mask == 0b1000_0000 {
				RoomTile::Semisolid(Direction::from_index(index & 0b0000_0011))
			}
			else if mask == 0b0000_0000 {
				RoomTile::Solid(index - 1)
			}
			else {
				panic!();
			}
		}
	}

	pub fn into_raw(self) -> u8 {
		match self {
			Self::Empty => 0,
			Self::Solid(x) => {
				let new = x + 1;
				assert!(new <= 0b0011_1111);
				new
			}
			Self::Semisolid(dir) => 0b1000_0000 | dir.into_index(),
			Self::Spike(dir) => 0b0100_0000 | dir.into_index(),
		}
	}
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Direction {
	Right = 0,
	Up = 1,
	Left = 2,
	Down = 3,
}

impl Direction {
	#[must_use]
	pub fn from_index(index: u8) -> Self {
		debug_assert!(index <= 0b11);
		match index {
			0b00 => Self::Right,
			0b01 => Self::Up,
			0b10 => Self::Left,
			0b11 => Self::Down,
			_ => unreachable!(),
		}
	}

	#[must_use]
	pub fn into_index(self) -> u8 {
		self as u8
	}
}

fn chunk<const N: usize>(buf: &[u8]) -> (Option<[u8; N]>, &[u8]) {
	if let Some((a, b)) = buf.split_at_checked(N) {
		let c = a.as_array().copied();
		(c, b)
	}
	else {
		(None, buf)
	}
}

fn consume<const N: usize>(buf: &mut &[u8]) -> Option<[u8; N]> {
	let (a, b) = chunk(buf);
	let a = a?;
	*buf = b;
	Some(a)
}

fn chunk_str(buf: &[u8]) -> (Option<&[u8]>, &[u8]) {
	if let Some(a) = buf.iter()
		.enumerate()
		.find(|(_, x)| **x == 0)
		.map(|(i, _)| i)
	{
		let (b, c) = buf.split_at(a);
		(Some(b), c)
	}
	else {
		(None, buf)
	}
}

fn consume_str<'a>(buf: &mut &'a [u8]) -> Option<&'a [u8]> {
	let (a, b) = chunk_str(buf);
	let a = a?;
	*buf = b;
	Some(a)
}

#[derive(Debug)]
pub enum ReadError {
	EmptyBuffer,
	NotEmptyBuffer,
	InvalidUtf8,
	FailedMagicNullstars,
	FailedMagicType,
	UnknownVersion,
}

trait Next: Sized {
	fn next(buf: &mut &[u8]) -> Result<Self, ReadError>;
}

impl Next for String {
	fn next(buf: &mut &[u8]) -> Result<Self, ReadError> {
		consume_str(buf)
			.ok_or(ReadError::EmptyBuffer)
			// first convert to cstr to deal with nul-terminated buffer
			.map(|x| core::ffi::CStr::from_bytes_until_nul(x)
				// consume_str() is supposed to always return with a nul
				.expect("unreachable"))
			.and_then(|x| x.to_str()
				.map_err(|_| ReadError::InvalidUtf8))
			.map(std::string::ToString::to_string)
	}
}

impl Next for u8 {
	fn next(buf: &mut &[u8]) -> Result<Self, ReadError> {
		consume(buf)
			.ok_or(ReadError::EmptyBuffer)
			.map(Self::from_le_bytes)
	}
}

impl Next for u16 {
	fn next(buf: &mut &[u8]) -> Result<Self, ReadError> {
		consume(buf)
			.ok_or(ReadError::EmptyBuffer)
			.map(Self::from_le_bytes)
	}
}

impl Next for u32 {
	fn next(buf: &mut &[u8]) -> Result<Self, ReadError> {
		consume(buf)
			.ok_or(ReadError::EmptyBuffer)
			.map(Self::from_le_bytes)
	}
}

#[must_use]
pub fn pack_world(world: &World) -> Vec<u8> {
	let mut buf = Vec::new();

	buf.extend_from_slice(MAGIC_TAG.as_bytes());
	buf.push(0);

	buf.extend_from_slice(MAGIC_WORLD.as_bytes());
	buf.push(0);

	buf.extend_from_slice(&VERSION_WORLD.to_le_bytes());

	for room in &world.rooms {
		buf.extend_from_slice(room.name.as_bytes());
		buf.push(0);

		buf.extend_from_slice(&room.x.to_le_bytes());
		buf.extend_from_slice(&room.y.to_le_bytes());
		buf.extend_from_slice(&room.width.to_le_bytes());
		buf.extend_from_slice(&room.height.to_le_bytes());
	}

	buf
}

pub fn unpack_world(mut buf: &[u8]) -> Result<World, ReadError> {
	let magic_nullstars = String::next(&mut buf)?;
	if magic_nullstars != MAGIC_TAG {
		return Err(ReadError::FailedMagicNullstars);
	}

	let magic_world = String::next(&mut buf)?;
	if magic_world != MAGIC_WORLD {
		return Err(ReadError::FailedMagicType);
	}

	let version = u16::next(&mut buf)?;
	if version != 0 {
		return Err(ReadError::UnknownVersion);
	}

	let size = u32::next(&mut buf)?;
	let mut rooms = Vec::new();

	for _ in 0..size {
		let name = String::next(&mut buf)?;
		let x = u32::next(&mut buf)?.cast_signed();
		let y = u32::next(&mut buf)?.cast_signed();
		let width = u32::next(&mut buf)?;
		let height = u32::next(&mut buf)?;

		rooms.push(WorldRoom {
			name,
			x,
			y,
			width,
			height,
		});
	}

	if !buf.is_empty() {
		return Err(ReadError::NotEmptyBuffer);
	}

	let world = World {
		rooms,
	};

	Ok(world)
}

#[must_use]
pub fn pack_room(room: &Room) -> Vec<u8> {
	let mut buf = Vec::new();

	buf.extend_from_slice(MAGIC_TAG.as_bytes());
	buf.push(0);

	buf.extend_from_slice(MAGIC_ROOM.as_bytes());
	buf.push(0);

	buf.extend_from_slice(&VERSION_ROOM.to_le_bytes());

	buf.extend_from_slice(&room.width.to_le_bytes());
	buf.extend_from_slice(&room.height.to_le_bytes());

	let size = room.width * room.height;

	assert_eq!(size, room.tiles.len().try_into().unwrap());

	buf.extend_from_slice(&size.to_le_bytes());
	for tile in &room.tiles {
		let index = tile.into_raw();
		buf.push(index);
	}

	let size: u32 = room.entities.len().try_into().unwrap();
	buf.extend_from_slice(&size.to_le_bytes());
	for entity in &room.entities {
		buf.extend_from_slice(entity.name.as_bytes());
		buf.push(0);
		buf.extend_from_slice(&entity.x.to_le_bytes());
		buf.extend_from_slice(&entity.y.to_le_bytes());
	}

	buf
}

pub fn unpack_room(mut buf: &[u8]) -> Result<Room, ReadError> {
	let magic_nullstars = String::next(&mut buf)?;
	if magic_nullstars != MAGIC_TAG {
		return Err(ReadError::FailedMagicNullstars);
	}

	let magic_room = String::next(&mut buf)?;
	if magic_room != MAGIC_WORLD {
		return Err(ReadError::FailedMagicType);
	}

	let version = u16::next(&mut buf)?;
	if version != 0 {
		return Err(ReadError::UnknownVersion);
	}

	let width = u32::next(&mut buf)?;
	let height = u32::next(&mut buf)?;

	let mut tiles = Vec::new();

	let size = u32::next(&mut buf)?;
	for _ in 0..size {
		let tile = u8::next(&mut buf)?;
		tiles.push(RoomTile::from_raw(tile));
	}

	let mut entities = Vec::new();

	let size = u32::next(&mut buf)?;
	for _ in 0..size {
		let name = String::next(&mut buf)?;
		let x = u32::next(&mut buf)?.cast_signed();
		let y = u32::next(&mut buf)?.cast_signed();

		entities.push(Entity {
			name,
			x,
			y,
		});
	}

	let room = Room {
		x_offset: 0,
		y_offset: 0,
		width,
		height,
		entities,
		tiles,
	};

	Ok(room)
}
