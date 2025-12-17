package mustachio

import "base:runtime"
import vmem "core:mem/virtual"
import "core:testing"

expect_expr :: proc(
	t: ^testing.T,
	expr: Expr,
	expected: string,
	allocator: runtime.Allocator,
	loc := #caller_location,
) {

	expr_as_str := expr_to_string(expr, allocator)
	testing.expect_value(t, expr_as_str, expected)
}

@(test)
test_parser__text_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "This is only a piece of text\nwith multiple lines\n"
	parser := parser_create(source, allocator)

	expr, eof := parser_next_expr(&parser)
	expect_expr(t, expr, "Text{This is only a piece of text\nwith multiple lines\n}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")
}

@(test)
test_parser__tag_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{tag}}"
	parser := parser_create(source, allocator)

	expr, eof := parser_next_expr(&parser)
	expect_expr(t, expr, "Tag{tag}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")
}

@(test)
test_parser__text_with_tag :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "begin {{tag}} end"
	parser := parser_create(source, allocator)

	expr, eof := parser_next_expr(&parser)
	expect_expr(t, expr, "Text{begin }", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	expect_expr(t, expr, "Tag{tag}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	expect_expr(t, expr, "Text{ end}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")

}

@(test)
test_parser__section_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{#tag}}{{name}}some text{{/tag}}"
	parser := parser_create(source, allocator)

	expr, eof := parser_next_expr(&parser)
	expect_expr(t, expr, "Section{tag [Tag{name}, Text{some text}]}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")
}

@(test)
test_parser__mistached_section :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{#tag}}{{name}}some text{{/badtag}}"
	parser := parser_create(source, allocator)

	expr, eof := parser_next_expr(&parser)
	expect_value_as_string(
		t,
		parser.errors,
		`["Error: [line 1] Mismatch between the head and end of section varnames."]`,
	)

	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	testing.expect(t, eof)

}

@(test)
test_parser__text_with_section :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "begin {{#tag}}before {{name}} after{{/tag}} end"
	parser := parser_create(source, allocator)

	expr, eof := parser_next_expr(&parser)
	expect_expr(t, expr, "Text{begin }", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	expect_expr(t, expr, "Section{tag [Text{before }, Tag{name}, Text{ after}]}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	expect_expr(t, expr, "Text{ end}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")

}

@(test)
test_parser__nested_section :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "begin {{#tag}}before {{#tag2}}{{name}}{{/tag2}} after{{/tag}} end"
	parser := parser_create(source, allocator)

	expr, eof := parser_next_expr(&parser)
	expect_expr(t, expr, "Text{begin }", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	expect_expr(
		t,
		expr,
		"Section{tag [Text{before }, Section{tag2 [Tag{name}]}, Text{ after}]}",
		allocator,
	)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	expect_expr(t, expr, "Text{ end}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")

}

@(test)
test_parser__inverted_section_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{^tag}}{{name}}some text{{/tag}}"
	parser := parser_create(source, allocator)

	expr, eof := parser_next_expr(&parser)
	expect_expr(t, expr, "Section{tag(inverted) [Tag{name}, Text{some text}]}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")
}

@(test)
test_parser__text_with_inverted_section :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "begin {{^tag}}before {{name}} after{{/tag}} end"
	parser := parser_create(source, allocator)

	expr, eof := parser_next_expr(&parser)
	expect_expr(t, expr, "Text{begin }", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	expect_expr(
		t,
		expr,
		"Section{tag(inverted) [Text{before }, Tag{name}, Text{ after}]}",
		allocator,
	)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	expect_expr(t, expr, "Text{ end}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")

}

@(test)
test_parser__comment :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "Some Text{{!a comment}} and more text."
	parser := parser_create(source, allocator)

	expr, eof := parser_next_expr(&parser)
	expect_expr(t, expr, "Text{Some Text}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	expect_expr(t, expr, "Comment{a comment}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	expect_expr(t, expr, "Text{ and more text.}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")
}

@(test)
test_parser__partial_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{>name}}"
	parser := parser_create(source, allocator)

	expr, eof := parser_next_expr(&parser)
	expect_expr(t, expr, "Partial{name}", allocator)
	testing.expect(t, !eof)

	expr, eof = parser_next_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")
}
