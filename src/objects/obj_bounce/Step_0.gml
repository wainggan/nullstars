
anim_vel += -anim_bounce * 0.15;
anim_vel *= 0.8;
anim_bounce += anim_vel;
anim_bounce *= 0.99;

ds_list_clear(cache_actors);
instance_place_list(x, y, obj_Entity, cache_actors, false);
for (var i := 0; i < ds_list_size(cache_actors); i++) {
	var _inst := cache_actors[| i];
	if array_contains(_inst.fn_impl(), "bounce") {
		_inst.fn_impl_bounce(0, x, bbox_top);
		anim_bounce = 1;
	}
}

