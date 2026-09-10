
ASSERT(instance_number(object_index) == 1);

light = instance_create_layer(x, y, layer, obj_light);

pet_menu := instance_create_layer(x, y, "Instances", obj_flag_menu);
with pet_menu {
	x = other.bbox_left;
	y = other.bbox_top;
	image_xscale = other.bbox_right - other.bbox_left;
	image_yscale = other.bbox_bottom - other.bbox_top;
	target = global.game.menu.page_none;
	priority = 1;
}

