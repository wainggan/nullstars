/// obj_Actor.Create

/*
 * object representing an active thing in the room, which
 * collides with the scene and other actors.
 * 
 * see `scr_obj_actor`
 */

event_inherited();

// speed
x_vel := 0;
y_vel := 0;

// fractional part of x/y
x_rem := 0;
y_rem := 0;

// updated when moved by an obj_Solid
lift_x := 0;
lift_y := 0;
lift_last_time := 0;
lift_last_x := 0;
lift_last_y := 0;

event := new Event();

fn_riding := obj_actor_riding;
fn_squish := obj_actor_squish;

fn_lift_get_x := obj_actor_lift_get_x;
fn_lift_get_y := obj_actor_lift_get_y;

fn_lift_set := obj_actor_lift_set;
fn_lift_update := obj_actor_lift_update;

fn_move_x := obj_actor_move_x;
fn_move_y := obj_actor_move_y;

fn_collision := obj_actor_collision;

