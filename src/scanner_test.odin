package mustachio

import vmem "core:mem/virtual"
import "core:testing"

expect_next_token :: proc(
	t: ^testing.T,
	scanner: ^Scanner,
	exp_type: TokenType,
	exp_lexeme := "",
	loc := #caller_location,
) {

	token := next_token(scanner)
	testing.expect_value(t, token.type, exp_type)
	if exp_type == .Text {
		testing.expect_value(t, token.lexeme, exp_lexeme, loc = loc)
	}
}

@(test)
test_scanner__text_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "This is only a piece of text\nwith multiple lines\n"
	scanner := create_scanner(source, allocator)

	expect_next_token(t, &scanner, .Text, source)
	expect_next_token(t, &scanner, .End_Of_File)
}

@(test)
test_scanner__tag_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{ tag }}"
	scanner := create_scanner(source, allocator)

	expect_next_token(t, &scanner, .Open_Tag)
	expect_next_token(t, &scanner, .Text, " tag ")
	expect_next_token(t, &scanner, .Close_Tag)
	expect_next_token(t, &scanner, .End_Of_File)
}

@(test)
test_scanner__text_with_tag :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "begin {{tag}} end"
	scanner := create_scanner(source, allocator)

	expect_next_token(t, &scanner, .Text, "begin ")
	expect_next_token(t, &scanner, .Open_Tag)
	expect_next_token(t, &scanner, .Text, "tag")
	expect_next_token(t, &scanner, .Close_Tag)
	expect_next_token(t, &scanner, .Text, " end")
	expect_next_token(t, &scanner, .End_Of_File)
}

@(test)
test_scanner__section_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{#tag}}"
	scanner := create_scanner(source, allocator)

	expect_next_token(t, &scanner, .Open_Section)
	expect_next_token(t, &scanner, .Text, "tag")
	expect_next_token(t, &scanner, .Close_Tag)
	expect_next_token(t, &scanner, .End_Of_File)
}

@(test)
test_scanner__end_section_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{/tag}}"
	scanner := create_scanner(source, allocator)

	expect_next_token(t, &scanner, .Open_End_Of_Section)
	expect_next_token(t, &scanner, .Text, "tag")
	expect_next_token(t, &scanner, .Close_Tag)
	expect_next_token(t, &scanner, .End_Of_File)
}

@(test)
test_scanner__inverted_section_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{^tag}}"
	scanner := create_scanner(source, allocator)

	expect_next_token(t, &scanner, .Open_Inverted_Section)
	expect_next_token(t, &scanner, .Text, "tag")
	expect_next_token(t, &scanner, .Close_Tag)
	expect_next_token(t, &scanner, .End_Of_File)
}

@(test)
test_scanner__partial_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{>tag}}"
	scanner := create_scanner(source, allocator)

	expect_next_token(t, &scanner, .Open_Partial)
	expect_next_token(t, &scanner, .Text, "tag")
	expect_next_token(t, &scanner, .Close_Tag)
}

@(test)
test_scanner__section_with_content :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "begin{{#tag}}name={{name}}{{/tag}}end"
	scanner := create_scanner(source, allocator)

	expect_next_token(t, &scanner, .Text, "begin")
	expect_next_token(t, &scanner, .Open_Section)
	expect_next_token(t, &scanner, .Text, "tag")
	expect_next_token(t, &scanner, .Close_Tag)
	expect_next_token(t, &scanner, .Text, "name=")
	expect_next_token(t, &scanner, .Open_Tag)
	expect_next_token(t, &scanner, .Text, "name")
	expect_next_token(t, &scanner, .Close_Tag)
	expect_next_token(t, &scanner, .Open_End_Of_Section)
	expect_next_token(t, &scanner, .Text, "tag")
	expect_next_token(t, &scanner, .Close_Tag)
	expect_next_token(t, &scanner, .Text, "end")
	expect_next_token(t, &scanner, .End_Of_File)
}
