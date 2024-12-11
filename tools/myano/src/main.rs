
mod error;
mod token;
mod parse;
mod expr;
mod resolve;
// mod evaluate;
mod runner;
// mod vm;

#[cfg(test)]
mod test;

fn main() {
	let mut reporter = error::Reporter::new();

	let file = match std::fs::read_to_string("input.myano") {
		Ok(v) => v,
		Err(e) => panic!("{}", e),
	};

	let tokens = token::tokenize(&mut reporter, &file);
	println!("{:?}", tokens);

	let ast = parse::parse(&mut reporter, &tokens);
	println!("{:?}", ast);

	resolve::resolve(&mut reporter, &ast);

	reporter.print();

}

