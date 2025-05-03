
function Cutscene() {
	
	static init = function () {

	};
	
	static update = function () {
		
	};
	
	static complete = function () {
		return true;
	};
	
}

function CutsceneCamera(_from_x, _from_y, _to_x, _to_y) : Cutscene() constructor {
	
	x = _from_x;
	y = _from_y;
	x_target = _to_x;
	y_target = _to_y;
	
	static init = function () {
		
	};
	
	static update = function () {
		
	};
	
}

function CutsceneRespawn() : Cutscene() constructor {
	
	
	static init = function () {
		
	};
	
	static update = function () {

	};
	
}


