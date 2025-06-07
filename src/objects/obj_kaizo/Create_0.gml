
image_xscale = jorp_w;
image_yscale = jorp_h;

event_inherited();

pet = instance_create_layer(x, y, layer, obj_Solid, {
	image_xscale: sprite_width,
	image_yscale: sprite_height,
});



