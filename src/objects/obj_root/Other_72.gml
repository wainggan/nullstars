
for (var i = 0; i < array_length(async_listen); i++) {
	var _item = async_listen[i];
	if ds_map_find_value(async_load, "id") == _item.load_id {
		if (!ds_map_find_value(async_load, "status")) {
			LOG(Log.error, $"level id={_item.level.id} couldn't be loaded. does it even exist?");
			LOG(Log.error, "this is an unrecoverable error. fuck you. crashing now");
			ASSERT(false);
		}
		_item.complete = true;
		array_delete(async_listen, i--, 1);
	}
}

