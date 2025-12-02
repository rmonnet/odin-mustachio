package mustachio

import "base:runtime"

// Simple Stack to keep track of opened sections.
Stack :: struct {
	data: [dynamic]string,
}

create_stack :: proc(allocator: runtime.Allocator) -> Stack {

	return Stack{data = make([dynamic]string, allocator)}
}

destroy_stack :: proc(s: ^Stack) {

	for element in s.data {
		delete(element)
	}
	delete(s.data)
}

stack_push :: proc(s: ^Stack, name: string) {

	append(&s.data, name)
}

stack_pop :: proc(s: ^Stack) {

	unordered_remove(&s.data, len(s.data) - 1)
}

stack_peek :: proc(s: Stack) -> string {

	return s.data[len(s.data) - 1]
}

stack_is_empty :: proc(s: Stack) -> bool {
	return len(s.data) == 0
}
