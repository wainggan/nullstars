
/*
 * object representing something that can be loaded dynamically
 * by the level loading system (and thus can be automatically 
 * freed using instance_destroy() at any time)
 * 
 * useful for decorative objects that only need to exist and
 * not much else
 */

/// used for staggering bounds checks. probably a bad idea to change this
parity = irandom(GAME_PARITY_ENTITY);

/// figure out if an obj_Exists is inside the camera bounds. used to figure out when to delete
/// the instance.
/// 
/// THIS SHOULD NEVER LIE. IF IT DOESN'T RETURN A CORRECT VALUE, DISASTROUS CONSEQUENCES ARE IN ORDER.
outside = exists_outside_default();

