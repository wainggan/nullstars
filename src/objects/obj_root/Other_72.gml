
for (var i = 0; i < array_length(async_listen); i++) {
	var _item = async_listen[i];
	if ds_map_find_value(async_load, "id") == _item.load_id {
		ASSERT(ds_map_find_value(async_load, "status"));
		_item.complete = true;
		array_delete(async_listen, i--, 1);
	}
}

