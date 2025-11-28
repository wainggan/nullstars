/// obj_Entity.Create

/*
 * object representing something that can meaningfully do literally anything
 * 
 * see `scr_obj_entity`
 */

event_inherited();

collidable := true;

// returns list of interfaces
fn_impl := obj_entity_impl;

// runs when the scene "resets".
// the object should return to the same state it was
// initialized.
fn_reset := obj_entity_reset;

// camera offset
fn_cam := obj_entity_cam;

