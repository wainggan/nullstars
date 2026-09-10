
event_inherited()

game_checkpoint_add(self);

light := noone;

pet_menu := instance_create_layer(x, y, "Instances", obj_flag_menu);
with pet_menu {
	x = other.bbox_left;
	y = other.bbox_top;
	image_xscale = other.bbox_right - other.bbox_left;
	image_yscale = other.bbox_bottom - other.bbox_top;
	target = global.game.menu.page_none;
	at_x = other.x;
	at_y = other.bbox_bottom + 4;
	priority = 1;
}
