
global.onoff = 1;

timer = 0;
timer_active = false;
timer_target = undefined;

checkpoint = undefined;

instance_create_layer(0, 0, layer, camera);
instance_create_layer(0, 0, layer, render);

room_goto(rm_game);

show_debug_overlay(true, true);
