/**
returns a lookup table. see: `ns_level_autotile_neighbor_to_neighbor_index()`.
*/
function ns_level_autotile_lut_neighbor_index_to_blob_resolved_offset_index() {
	static __array = undefined;
	
	/*
	   1   2   4
	   8   ?  16
	  32  64 128
	
	00000001  00000010  00000100
	
	00001000  xxxxxxxx  00010000
	
	00100000  01000000  10000000
	*/
	
	if __array == undefined {
		// fill with undefined, in the hope that retrieving an invalid value results in a crash.
		__array := array_create(256, undefined);
		
		// o o o
		// o : o
		// o o o
		__array[0b0000_0000] := 3;
		
		// o = o
		// o : o
		// o o o
		__array[0b0000_0010] := 21;
		
		// o o o
		// = : o
		// o o o
		__array[0b0000_1000] := 2;
		
		// o = o
		// = : o
		// o o o
		__array[0b0000_1010] := 38;
		
		// = = o
		// = : o
		// o o o
		__array[0b0000_1011] := 20;
		
		// o o o
		// o : =
		// o o o
		__array[0b0001_0000] := 0;
		
		// o = o
		// o : =
		// o o o
		__array[0b0001_0010] := 36;
		
		// o = =
		// o : =
		// o o o
		__array[0b0001_0110] := 18;
		
		// o o o
		// = : =
		// o o o
		__array[0b0001_1000] := 1;
		
		// o = o
		// = : =
		// o o o
		__array[0b0001_1010] := 37;
		
		// = = o
		// = : =
		// o o o
		__array[0b0001_1011] := 10;
		
		// o = =
		// = : =
		// o o o
		__array[0b0001_1110] := 11;
		
		// = = =
		// = : =
		// o o o
		__array[0b0001_1111] := 19;
		
		// o o o
		// o : o
		// o = o
		__array[0b0100_0000] := 9;
		
		// o = o
		// o : o
		// o = o
		__array[0b0100_0010] := 15;
		
		// o o o
		// = : o
		// o = o
		__array[0b0100_1000] := 26;
		
		// o = o
		// = : o
		// o = o
		__array[0b0100_1010] := 32;
		
		// = = o
		// = : o
		// o = o
		__array[0b0100_1011] := 17;
		
		// o o o
		// o : =
		// o = o
		__array[0b0101_0000] := 24;
		
		// o = o
		// o : =
		// o = o
		__array[0b0101_0010] := 30;
		
		// o = =
		// o : =
		// o = o
		__array[0b0101_0110] := 16;
		
		// o o o
		// = : =
		// o = o
		__array[0b0101_1000] := 25;
		
		// o = o
		// = : =
		// o = o
		__array[0b0101_1010] := 31;
		
		// = = o
		// = : =
		// o = o
		__array[0b0101_1011] := 44;
		
		// o = =
		// = : =
		// o = o
		__array[0b0101_1110] := 45;
		
		// = = =
		// = : =
		// o = o
		__array[0b0101_1111] := 28;
		
		// o o o
		// = : o
		// = = o
		__array[0b0110_1000] := 8;
		
		// o = o
		// = : o
		// = = o
		__array[0b0110_1010] := 23;
		
		// = = o
		// = : o
		// = = o
		__array[0b0110_1011] := 14;
		
		// o o o
		// = : =
		// = = o
		__array[0b0111_1000] := 4;
		
		// o = o
		// = : =
		// = = o
		__array[0b0111_1010] := 46;
		
		// = = o
		// = : =
		// = = o
		__array[0b0111_1011] := 33;
		
		// o = =
		// = : =
		// = = o
		__array[0b0111_1110] := 43;
		
		// = = =
		// = : =
		// = = o
		__array[0b0111_1111] := 27;
		
		// o o o
		// o : =
		// o = =
		__array[0b1101_0000] := 6;
		
		// o = o
		// o : =
		// o = =
		__array[0b1101_0010] := 22;
		
		// o = =
		// o : =
		// o = =
		__array[0b1101_0110] := 12;
		
		// o o o
		// = : =
		// o = =
		__array[0b1101_1000] := 5;
		
		// o = o
		// = : =
		// o = =
		__array[0b1101_1010] := 47;
		
		// = = o
		// = : =
		// o = =
		__array[0b1101_1011] := 42;
		
		// o = =
		// = : =
		// o = =
		__array[0b1101_1110] := 35;
		
		// = = =
		// = : =
		// o = =
		__array[0b1101_1111] := 29;
		
		// o o o
		// = : =
		// = = =
		__array[0b1111_1000] := 7;
		
		// o = o
		// = : =
		// = = =
		__array[0b1111_1010] := 40;
		
		// = = o
		// = : =
		// = = =
		__array[0b1111_1011] := 39;
		
		// o = =
		// = : =
		// = = =
		__array[0b1111_1110] := 41;
		
		// = = =
		// = : =
		// = = =
		__array[0b1111_1111] := 3;
	}
	
	return __array;
}


/**
returns a lookup table. see: `ns_level_autotile_neighbor_to_neighbor_index()`.

this can be used to index into the `ns_level_autotile_lut_offset_index_to_offset_position()` lookup-table.

@return {array<real>}
*/
function ns_level_autotile_lut_neighbor_index_to_blob_offset_index() {
	static __array = undefined;
	
	/*
	   1   2   4
	   8   ?  16
	  32  64 128
	
	00000001  00000010  00000100
	
	00001000  xxxxxxxx  00010000
	
	00100000  01000000  10000000
	*/
	
	if __array == undefined {
		// fill with undefined, in the hope that retrieving an invalid value results in a crash.
		__array := array_create(256, undefined);
		
		// o o o
		// o : o
		// o o o
		__array[0b0000_0000] := 0;
		
		// o = o
		// o : o
		// o o o
		__array[0b0000_0010] := 1;
		
		// o o o
		// = : o
		// o o o
		__array[0b0000_1000] := 2;
		
		// o = o
		// = : o
		// o o o
		__array[0b0000_1010] := 3;
		
		// = = o
		// = : o
		// o o o
		__array[0b0000_1011] := 4;
		
		// o o o
		// o : =
		// o o o
		__array[0b0001_0000] := 5;
		
		// o = o
		// o : =
		// o o o
		__array[0b0001_0010] := 6;
		
		// o = =
		// o : =
		// o o o
		__array[0b0001_0110] := 7;
		
		// o o o
		// = : =
		// o o o
		__array[0b0001_1000] := 8;
		
		// o = o
		// = : =
		// o o o
		__array[0b0001_1010] := 9;
		
		// = = o
		// = : =
		// o o o
		__array[0b0001_1011] := 10;
		
		// o = =
		// = : =
		// o o o
		__array[0b0001_1110] := 11;
		
		// = = =
		// = : =
		// o o o
		__array[0b0001_1111] := 12;
		
		// o o o
		// o : o
		// o = o
		__array[0b0100_0000] := 13;
		
		// o = o
		// o : o
		// o = o
		__array[0b0100_0010] := 14;
		
		// o o o
		// = : o
		// o = o
		__array[0b0100_1000] := 15;
		
		// o = o
		// = : o
		// o = o
		__array[0b0100_1010] := 16;
		
		// = = o
		// = : o
		// o = o
		__array[0b0100_1011] := 17;
		
		// o o o
		// o : =
		// o = o
		__array[0b0101_0000] := 18;
		
		// o = o
		// o : =
		// o = o
		__array[0b0101_0010] := 19;
		
		// o = =
		// o : =
		// o = o
		__array[0b0101_0110] := 20;
		
		// o o o
		// = : =
		// o = o
		__array[0b0101_1000] := 21;
		
		// o = o
		// = : =
		// o = o
		__array[0b0101_1010] := 22;
		
		// = = o
		// = : =
		// o = o
		__array[0b0101_1011] := 23;
		
		// o = =
		// = : =
		// o = o
		__array[0b0101_1110] := 24;
		
		// = = =
		// = : =
		// o = o
		__array[0b0101_1111] := 25;
		
		// o o o
		// = : o
		// = = o
		__array[0b0110_1000] := 26;
		
		// o = o
		// = : o
		// = = o
		__array[0b0110_1010] := 27;
		
		// = = o
		// = : o
		// = = o
		__array[0b0110_1011] := 28;
		
		// o o o
		// = : =
		// = = o
		__array[0b0111_1000] := 29;
		
		// o = o
		// = : =
		// = = o
		__array[0b0111_1010] := 30;
		
		// = = o
		// = : =
		// = = o
		__array[0b0111_1011] := 31;
		
		// o = =
		// = : =
		// = = o
		__array[0b0111_1110] := 32;
		
		// = = =
		// = : =
		// = = o
		__array[0b0111_1111] := 33;
		
		// o o o
		// o : =
		// o = =
		__array[0b1101_0000] := 34;
		
		// o = o
		// o : =
		// o = =
		__array[0b1101_0010] := 35;
		
		// o = =
		// o : =
		// o = =
		__array[0b1101_0110] := 36;
		
		// o o o
		// = : =
		// o = =
		__array[0b1101_1000] := 37;
		
		// o = o
		// = : =
		// o = =
		__array[0b1101_1010] := 38;
		
		// = = o
		// = : =
		// o = =
		__array[0b1101_1011] := 39;
		
		// o = =
		// = : =
		// o = =
		__array[0b1101_1110] := 40;
		
		// = = =
		// = : =
		// o = =
		__array[0b1101_1111] := 41;
		
		// o o o
		// = : =
		// = = =
		__array[0b1111_1000] := 42;
		
		// o = o
		// = : =
		// = = =
		__array[0b1111_1010] := 43;
		
		// = = o
		// = : =
		// = = =
		__array[0b1111_1011] := 44;
		
		// o = =
		// = : =
		// = = =
		__array[0b1111_1110] := 45;
		
		// = = =
		// = : =
		// = = =
		__array[0b1111_1111] := 46;
	}
	
	return __array;
}

function ns_level_autotile_lut_offset_index_to_offset_position(_id) {
	static __array = undefined;
	
	if __array == undefined {
		__array := array_create(48);
		
		__array[0] := { x: 3, y: 0 };
		
		__array[1] := { x: 3, y: 3 };
		
		__array[2] := { x: 2, y: 0 };
		
		__array[3] := { x: 2, y: 6 };
		
		__array[4] := { x: 2, y: 3 };
		
		__array[5] := { x: 0, y: 0 };
		
		__array[6] := { x: 0, y: 6 };
		
		__array[7] := { x: 0, y: 3 };
		
		__array[8] := { x: 1, y: 0 };
		
		__array[9] := { x: 1, y: 6 };
		
		__array[10] := { x: 4, y: 1 };
		
		__array[11] := { x: 5, y: 1 };
		
		__array[12] := { x: 1, y: 3 };
		
		__array[13] := { x: 3, y: 1 };
		
		__array[14] := { x: 3, y: 2 };
		
		__array[15] := { x: 2, y: 4 };
		
		__array[16] := { x: 2, y: 5 };
		
		__array[17] := { x: 5, y: 2 };
		
		__array[18] := { x: 0, y: 4 };
		
		__array[19] := { x: 0, y: 5 };
		
		__array[20] := { x: 4, y: 2 };
		
		__array[21] := { x: 1, y: 4 };
		
		__array[22] := { x: 1, y: 5 };
		
		__array[23] := { x: 2, y: 7 };
		
		__array[24] := { x: 3, y: 7 };
		
		__array[25] := { x: 4, y: 4 };
		
		__array[26] := { x: 2, y: 1 };
		
		__array[27] := { x: 5, y: 3 };
		
		__array[28] := { x: 2, y: 2 };
		
		__array[29] := { x: 4, y: 0 };
		
		__array[30] := { x: 4, y: 7 };
		
		__array[31] := { x: 3, y: 5 };
		
		__array[32] := { x: 1, y: 7 };
		
		__array[33] := { x: 3, y: 4 };
		
		__array[34] := { x: 0, y: 1 };
		
		__array[35] := { x: 4, y: 3 };
		
		__array[36] := { x: 0, y: 2 };
		
		__array[37] := { x: 5, y: 0 };
		
		__array[38] := { x: 5, y: 7 };
		
		__array[39] := { x: 0, y: 7 };
		
		__array[40] := { x: 5, y: 5 };
		
		__array[41] := { x: 5, y: 4 };
		
		__array[42] := { x: 1, y: 1 };
		
		__array[43] := { x: 4, y: 6 };
		
		__array[44] := { x: 3, y: 6 };
		
		__array[45] := { x: 5, y: 6 };
		
		__array[46] := { x: 4, y: 5 };
	}
	
	return __array[_id];
}

