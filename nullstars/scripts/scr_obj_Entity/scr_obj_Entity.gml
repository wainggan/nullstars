/// @self obj_Entity
function obj_Entity_fn_create() {
	fn_tick := obj_Entity_fn_tick;
	fn_draw := obj_Entity_fn_draw;
	fn_outside := obj_Entity_fn_outside;
	p_entity_mask = mask_index;
	p_entity_id = 0;
}

/// @self obj_Entity
function obj_Entity_fn_tick() {
	// empty
}

/// @self obj_Entity
function obj_Entity_fn_draw() {
	// empty
}

/// @self obj_Entity
function obj_Entity_fn_outside() {
	// todo: replace with check for camera
	return true;
}

/// @self obj_Entity
function obj_Entity_create() {
	self.fn_create();
}

/// @self obj_Entity
function obj_Entity_tick() {
	self.fn_tick();
}

/// @self obj_Entity
function obj_Entity_draw() {
	self.fn_draw();
}

/// @self obj_Entity
function obj_Entity_outside() {
	return self.fn_outside();
}

/// @self obj_Entity
function obj_Entity_set_collidable(_yes) {
	if _yes {
		self.mask_index = self.p_entity_mask;
	}
	else {
		self.p_entity_mask = mask_index;
		self.mask_index = spr_none;
	}
}

/// @self obj_Entity
function obj_Entity_get_collidable() {
	return self.mask_index != spr_none;
}

/// @self obj_Entity
function obj_Entity_set_mask(_mask) {
	self.p_entity_mask = self.mask_index;
	if self.mask_index != spr_none {
		self.mask_index = self.p_entity_mask;
	}
}

/// @self obj_Entity
function obj_Entity_get_mask() {
	return self.p_entity_mask;
}

/// @self obj_Entity
function obj_Entity_get_id() {
	return self.p_entity_id;
}
