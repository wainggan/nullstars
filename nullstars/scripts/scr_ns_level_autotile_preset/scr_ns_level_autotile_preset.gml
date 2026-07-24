// TODO: replace with json file

function ns_level_json_test() {
	static __out := {
		"stamps": [
		],
		"rules": [
			{
				"rule": "match",
				"match": {
					"condition": "tileset",
					"tileset": [2],
				},
				"then": {
					"rule": "list",
					"list": [
						{
							"rule": "match",
							"match": { "condition": "class", "class": [7, 4, 5, 25] },
							"then": {
								"rule": "emit",
								"emit": "single",
								"single": {
									"stamp": "choose",
									"choose": [
										{ "stamp": "tile", "src_x": 1, "src_y": 11, "rand_y_max": 1 },
										{ "stamp": "tile", "src_x": 2, "src_y": 11, "rand_y_max": 1 },
									],
								},
							},
						},
						{
							"rule": "match",
							"match": { "condition": "class", "class": [24, 6] },
							"then": {
								"rule": "emit",
								"emit": "single",
								"single": {
									"stamp": "choose",
									"choose": [
										{ "stamp": "tile", "src_x": 0, "src_y": 11 },
									],
								},
							},
						},
						{
							"rule": "match",
							"match": { "condition": "class", "class": [26, 8] },
							"then": {
								"rule": "emit",
								"emit": "single",
								"single": {
									"stamp": "choose",
									"choose": [
										{ "stamp": "tile", "src_x": 3, "src_y": 11 },
									],
								},
							},
						},
					],
				},
			},
			{
				"rule": "emit",
				"emit": "blob",
				"src_x": 0,
				"src_y": 1,
			},
		],
	};
	
	return __out;
}
