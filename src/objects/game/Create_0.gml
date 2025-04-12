
global.game = new Game();

instance_create_layer(0, 0, layer, render);
instance_create_layer(0, 0, layer, obj_music);
instance_create_layer(0, 0, layer, obj_menu);

room_goto(rm_game);

