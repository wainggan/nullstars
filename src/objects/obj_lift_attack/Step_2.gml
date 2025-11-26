// todo: this isn't correct.
// i wont elaborate
// todo: if a lift is pushing this attack, and the player stands on both, this ends up transfering both momentums.
with pet {
	solid_move(other.x - x, other.y - y);
}
