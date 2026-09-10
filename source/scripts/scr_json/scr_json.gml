/*
basic json handling.
*/

/**
writes to a file

@arg {string} _filename
*/
function nullstars_file_json_save(_filename, _tree) {
	LOG(Log.Hide, $"nullstars_file_json_save(): writing file {_filename}");
	
	var _string = json_stringify(_tree, true);
	var _buffer = buffer_create(string_byte_length(_string) + 1, buffer_fixed, 1);
	
	buffer_write(_buffer, buffer_string, _string);
	buffer_save(_buffer, _filename);
	buffer_delete(_buffer);
}

/**
opens a json file.

returns `-1` if an error occured.

@arg {string} _filename
@return {struct | real}
*/
function nullstars_file_json_load(_filename) {
	if !file_exists(_filename) {
		LOG(Log.Error, $"nullstars_file_json_load(): file {_filename} doesn't exist!");
		return -1;
	}
	
	LOG(Log.Note, $"nullstars_file_json_load(): loading file {_filename}");
	
	var _buffer = buffer_load(_filename);
	var _string = buffer_read(_buffer, buffer_string);
	buffer_delete(_buffer);
	
	var _data = json_parse(_string, undefined, true);
	
	// kill me
	// Feather ignore once GM1045
	return _data;
}
