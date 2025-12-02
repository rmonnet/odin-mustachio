package mustachio

import "base:runtime"
import "core:fmt"
import vmem "core:mem/virtual"
import "core:testing"

arena_init :: proc(a: ^vmem.Arena) -> runtime.Allocator {

	arena_err := vmem.arena_init_growing(a)
	ensure(arena_err == nil)
	return vmem.arena_allocator(a)
}

expect_value_as_string :: proc(
	t: ^testing.T,
	value: $T,
	expected: string,
	loc := #caller_location,
) {

	result := fmt.aprintf("%v", value)
	defer delete(result)
	testing.expect_value(t, result, expected, loc = loc)
}
