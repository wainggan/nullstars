// Feather ignore GM1051
#macro SETUP_OBJ_ENTITY \
	m_entity_mask = mask_index;

/// @self obj_Entity
function obj_Entity_set_collidable(_yes) {
	if _yes {
		self.mask_index = self.m_entity_mask;
	}
	else {
		self.m_entity_mask = mask_index;
		self.mask_index = spr_none;
	}
}

/// @self obj_Entity
function obj_Entity_get_collidable() {
	return self.mask_index == spr_none;
}

/// @self obj_Entity
function obj_Entity_set_mask(_mask) {
	self.m_entity_mask = self.mask_index;
	if self.mask_index != spr_none {
		self.mask_index = self.m_entity_mask;
	}
}

/// @self obj_Entity
function obj_Entity_get_mask() {
	return self.m_entity_mask;
}

/// @self obj_Entity
function obj_entity_impl() {
	static __return = [];
	return __return;
}

/// @self obj_Entity
function obj_entity_reset() {
	return;
}

/// @arg {struct.Camera} _cam
/// @self obj_Entity
function obj_entity_cam(_cam) {
	_cam.move(x, y);
}


/// preferred way to check for entity collision
function entity_at(_x, _y, _type) {
	static __list = ds_list_create();
	ds_list_clear(__list);
	
	instance_place_list(_x, _y, _type, __list, false);
	
	for (var i = 0; i < ds_list_size(__list); i++) {
		var _o = __list[| i];
		if _o.collidable {
			return _o;
		}
	}
	
	return noone;
}

