# nullstars package format

this describes nullstars' "package format", used for custom levels and assets (called "mods" in-game).

json will be documented using typescript types, and binary data will be described with rust types. care should be taken to follow this documentation exactly, as mistakes can, at worst, cause the game to crash without even an error.

## package.json

```ts
type Package = {
	/** the name of the package. displayed in the mods list. */
	"name": string;
	
	/** where the package can be located. must be a valid url. */
	"source": string;
	
	/** the description of the package. */
	"description": string;
	
	/** the version of the package. */
	"version": number;
	
	/** name of all authors. displayed in order specified by the array. */
	"authors": {
		/** author name. */
		"name": string;
		
		/** what the author is credited for. */
		"credit": string;
		
		/** where the author can be contacted. */
		"contact"?: string;
	}[];
	
	"assets": {
		""
	};
};
```

## tileset.json

```ts
type Tileset = {
	/** stamps are individual collections of tiles that can be reused. */
	"stamp": Stamp[];
	/** while the autotiler iterates over every tile, rules control which stamp to place. */
	"rules": RuleCriteria[];
};

type Stamp = {
	"id": string;
	"rule": RuleStamp;
};

type RuleStamp =
	| {
		"stamp": "choose";
		
		"choose": StampRule[];
	}
	| {
		"stamp": "list";
		
		"list": StampRule[];
	}
	| {
		"stamp": "tile";
		
		"src_x": number;
		"src_y": number;
		
		"off_x"?: number;
		"off_y"?: number;
		"off_z"?: number;
		
		"x_rand_min"?: number;
		"x_rand_max"?: number;
		"y_rand_min"?: number;
		"y_rand_max"?: number;
	};

type RuleCriteria =
	| {
		"type": "emit";
	} & (
		| {
			"type": "emit";
			"emit": "blob";
			"src_x": number;
			"src_y": number;
		}
		| {
			"emit": "stamp";
			"stamp": string[];
		}
		| {
			"emit": "single";
			"single": RuleStamp;
		}
	)
	| {
		"type": "match";
		"match": RuleCriteriaBool;
		"then": RuleCriteria;
		"else"?: RuleCriteria;
	}
	| {
		"type": "list";
		"list": RuleCriteria[];
	}
	| {
		"type": "overlay";
		"overlay": RuleCriteria[];
	}
	| {
		"type": "choose";
		"choose": RuleCriteria[];
	};

type RuleCriteriaBool =
	| {
		/** matches if all rules in `all` match. */
		"condition": "all";
		"all": RuleCriteriaBool[];
	}
	| {
		/** matches if at least one rule in `any` match. */
		"condition": "any";
		"any": RuleCriteriaBool[];
	}
	| {
		/** matches if no rules in `none` match. */
		"condition": "none";
		"any": RuleCriteriaBool[];
	}
	| {
		/** matches if the current tile's tileset id is in `match`. -1 matches any tileset. */
		"condition": "tileset";
		"tileset": number[];
	}
	| {
		/**
		matches if the current tile's neighbors match what is defined in the matrix.
		for example:
		
		"width": 3,
		"height": 3,
		"origin_x": 1,
		"origin_y": 1,
		"index": [
			0, 2, 2,
			0, 1, 2,
			0, 0, 0
		]
		
		first, the origin of the matrix is set to the middle (the top left corner is 0, 0).
		thus, this will match if the current tile is tileset 1, and the tile above, to
		the right, and top right, are tileset 2.
		
		special values:
		0: matches if there is nothing
		-1: matches any tileset
		-2: always matches
		-4: never matches (for debugging)
		
		anything outside of the matrix is treated as -2.
		*/
		"condition": "index";
		
		"width"?: number;
		"height"?: number;
		"origin_x"?: number;
		"origin_y"?: number;
		"mirror_w"?: boolean;
		"mirror_h"?: boolean;
		
		"index": number[];
	}
	| {
		/** matches if the current tile's sampled noise value is larger than `noise`. */
		"condition": "noise";
		"noise": number;
	};
```


