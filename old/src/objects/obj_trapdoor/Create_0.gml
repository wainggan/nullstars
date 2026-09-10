
event_inherited();

image_xscale = jorp_w;
image_yscale = jorp_h;

pet = instance_create_layer(x, y, "Instances", obj_Solid);
with pet {
	visible = false;
	fn_outside = exists_outside_empty();
	image_xscale = other.sprite_width;
	image_yscale = other.sprite_height;
	collidable = true;
}

locked = true;
locked_anim = 0;

fn_reset = function () {
	locked = true;
};
