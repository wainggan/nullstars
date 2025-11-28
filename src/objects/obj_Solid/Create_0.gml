/// obj_Solid.Create

/*
 * object representing anything impassable by
 * any obj_Actor. walls, moving platforms.
 * 
 * see `scr_obj_solid`
 */

event_inherited();

// fractional part of x/y
x_rem := 0;
y_rem := 0;

// updated to related speed when solid_move_#() is called
lift_x := 0;
lift_y := 0;

fn_move := obj_solid_move;

