// used to allow `break` statements in a block
#macro _BLOCK repeat 1

// comenting out a block with highlighting
#macro _IGNORE if true else

// use as
//     defer {
//         show_debug_message("second");
//     }
//     after {
//         show_debug_message("first");
//     }
#macro _DEFER for (;;{
#macro _AFTER ;break;})

// mark variable as const
#macro _CONST /* const */
_CONST;

// mark variable as mutable
#macro _MUT /* mut */
_MUT;

