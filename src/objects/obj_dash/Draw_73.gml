
var _c = state.is(state_active) ? c_white : #77aa77;
var _d = round_ext(dir, 9)

var _scale = 1 + max(anim_hit * 0.5, power(game_music_get_beat_lead(), 2) * 0.2);

draw_sprite_ext(sprite_index, 0, x, y, _scale, _scale, _d, _c, 1)


