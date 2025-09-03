
event_inherited();

image_xscale = jorp_w;
image_yscale = jorp_h;

pet = instance_create_layer(x, y, "Instances", obj_Solid);
with pet {
	visible = false;
	image_xscale = other.image_xscale;
	image_yscale = other.image_yscale;
	collidable = true;
}

locked = true;
locked_anim = 0;

reset = function () {
	locked = true;
};
