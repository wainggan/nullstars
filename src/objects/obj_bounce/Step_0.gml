
ds_list_clear(cache_actors);
instance_place_list(x, y, obj_player, cache_actors, false);
for (var i = 0; i < ds_list_size(cache_actors); i++) {
	var _inst = cache_actors[| i];
	_inst.event.call("bounce", 0, x, bbox_top);
}

