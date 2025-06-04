
image_xscale = jorp_w;
image_yscale = jorp_h;

event_inherited();

image_angle = 90;

var _e = image_xscale;
image_xscale = image_yscale;
image_yscale = _e;

y += TILESIZE;
