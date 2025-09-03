
draw_sprite_ext(spr_pixel, 0, x + 7, y, 18, sprite_height / 2 * locked_anim, 0, c_white, 1);
draw_sprite_ext(spr_pixel, 0, x + 7, y + sprite_height, 18, -sprite_height / 2 * locked_anim, 0, c_white, 1);

draw_sprite_stretched(spr_trapdoor, 0, x, y, 32, 32 + locked_anim * 6);
draw_sprite_stretched(spr_trapdoor, 0, x, y + sprite_height, 32, -(32 + locked_anim * 6));

