
use crate::error::Reporter;
use crate::token::{tokenize, Token};

#[test]
fn test_empty() {
	let mut reporter = Reporter::new();
	assert_eq!(
		tokenize(&mut reporter, ""),
		vec![
			Token::Eof,
		]
	);
}

#[test]
fn test_ints() {
	let mut reporter = Reporter::new();
	assert_eq!(
		tokenize(&mut reporter, "0 1 2 3 4 5 6 7 8 9 00 10 99"),
		vec![
			Token::Integer("0".to_string()),
			Token::Integer("1".to_string()),
			Token::Integer("2".to_string()),
			Token::Integer("3".to_string()),
			Token::Integer("4".to_string()),
			Token::Integer("5".to_string()),
			Token::Integer("6".to_string()),
			Token::Integer("7".to_string()),
			Token::Integer("8".to_string()),
			Token::Integer("9".to_string()),
			Token::Integer("00".to_string()),
			Token::Integer("10".to_string()),
			Token::Integer("99".to_string()),
			Token::Eof,
		]
	);
}

#[test]
fn test_floats() {
	let mut reporter = Reporter::new();
	assert_eq!(
		tokenize(&mut reporter, "1.0 1. 0. 1"),
		vec![
			Token::Float("1.0".to_string()),
			Token::Float("1.".to_string()),
			Token::Float("0.".to_string()),
			Token::Integer("1".to_string()),
			Token::Eof,
		]
	);
}
