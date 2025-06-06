
function draw_line_sprite(_x1, _y1, _x2, _y2, _width = 1, _col = draw_get_color(), _alpha = draw_get_alpha()) {
	
	var _dist = point_distance(_x1, _y1, _x2, _y2) // bad idea
	var _dir = point_direction(_x1, _y1, _x2, _y2) // bad idea
	draw_sprite_ext(spr_pixel, 0, _x1, _y1, _dist, _width, _dir, _col, _alpha)
	
}

function draw_circle_sprite_outline(_x, _y, _r, _width = 1, _col = draw_get_color(), _alpha = draw_get_alpha(), _res = 12) {
	
	var _lx = _r
	var _ly = 0
	
	for (var i = 1; i <= _res; i++) {
		
		var _d = 360 / _res * i
		
		var _nx = lengthdir_x(_r, _d)
		var _ny = lengthdir_y(_r, _d)
		
		draw_line_sprite(
			_x + _lx, _y + _ly,
			_x + _nx, _y + _ny,
			_width, _col, _alpha
		)
		
		_lx = _nx
		_ly = _ny
		
	}
	
}

/**
draw an outline of a circle with thickness
@arg {real} _x center of circle
@arg {real} _y center of circle
@arg {real} _radius the radius of the circle in pixels
@arg {real} _thick thickness of the circle in pixels
@arg {real} _percentage from 0 to 1, how much of the circle to draw
@arg {real} _start angle to start drawing from
@arg {bool} _anti true for counter-clockwise, false for clockwise
@arg {constant.Color} _color color to use
@arg {real} _alpha alpha to use
@arg {real} _res resolution of the circle
*/
function draw_circle_outline_part(_x, _y, _radius, _thick, _percentage, _start, _anti, _color = draw_get_color(), _alpha = draw_get_alpha(), _res = 32) {

	var _interval = 360 / _res;
	
	_anti = _anti ? -1 : 1;
	
	var _hthick = _thick / 2;
    
	draw_primitive_begin(pr_trianglestrip);
    
	for (var i = 0; i < _percentage * _res; i++) {
		var _angle = _start + _interval * i * _anti;
		var _dir_x = dcos(_angle);
		var _dir_y = -dsin(_angle);
        
		draw_vertex_color(_x + (_radius + _hthick) * _dir_x, _y + (_radius + _hthick) * _dir_y, _color, _alpha);
		draw_vertex_color(_x + (_radius - _hthick) * _dir_x, _y + (_radius - _hthick) * _dir_y, _color, _alpha);
	}
	
	var _angle = _start + _interval * _percentage * _res * _anti;
	var _dir_x = dcos(_angle);
	var _dir_y = -dsin(_angle);
	
	draw_vertex_color(_x + (_radius + _hthick) * _dir_x, _y + (_radius + _hthick) * _dir_y, _color, _alpha);
	draw_vertex_color(_x + (_radius - _hthick) * _dir_x, _y + (_radius - _hthick) * _dir_y, _color, _alpha);
	
	draw_primitive_end();
}

function draw_circle_outline(_x, _y, _radius, _thick, _color = undefined, _alpha = undefined, _res = undefined) {
	draw_circle_outline_part(_x, _y, _radius, _thick, 1, 0, false, _color, _alpha, _res)
}

// in a stroke of genius, i used this `_radius` parameter for diameter.
// @todo: go through every use of this function and fix it ig
function draw_circle_sprite(_x, _y, _radius, _color = draw_get_color(), _alpha = draw_get_alpha()) {
	draw_sprite_ext(spr_circle, 0, _x, _y, _radius / 64, _radius / 64, 0, _color, _alpha);
}
