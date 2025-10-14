
if anim_return {
	var _anchor_dist = point_distance(x, y, anim_anchor_x, anim_anchor_y);
	var _anchor_dir = point_direction(x, y, anim_anchor_x, anim_anchor_y);
	
	draw_sprite_ext(spr_eye_chain, 0, x, y, _anchor_dist / 32, 1, _anchor_dir, c_white, 1);
}
