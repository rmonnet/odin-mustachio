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
	parser := create_parser(source, allocator)

	advance(&parser)
	expr, eof := parse_expr(&parser)
	expect_expr(t, expr, "Text{This is only a piece of text\nwith multiple lines\n}", allocator)
	testing.expect(t, !eof)

	expr, eof = parse_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")
}

@(test)
test_parser__tag_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{tag}}"
	parser := create_parser(source, allocator)

	advance(&parser)
	expr, eof := parse_expr(&parser)
	expect_expr(t, expr, "Tag{tag}", allocator)
	testing.expect(t, !eof)

	expr, eof = parse_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")
}

@(test)
test_parser__text_with_tag :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "begin {{tag}} end"
	parser := create_parser(source, allocator)

	advance(&parser)
	expr, eof := parse_expr(&parser)
	expect_expr(t, expr, "Text{begin }", allocator)
	testing.expect(t, !eof)

	expr, eof = parse_expr(&parser)
	expect_expr(t, expr, "Tag{tag}", allocator)
	testing.expect(t, !eof)

	expr, eof = parse_expr(&parser)
	expect_expr(t, expr, "Text{ end}", allocator)
	testing.expect(t, !eof)

	expr, eof = parse_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")

}

@(test)
test_parser__section_only :: proc(t: ^testing.T) {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{#tag}}{{name}}some text{{/tag}}"
	parser := create_parser(source, allocator)

	advance(&parser)
	expr, eof := parse_expr(&parser)
	expect_expr(t, expr, "Section{tag[Tag{name}, Text{some text}]}", allocator)
	testing.expect(t, !eof)

	expr, eof = parse_expr(&parser)
	testing.expect(t, eof)

	expect_value_as_string(t, parser.errors, "[]")
}
