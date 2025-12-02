package mustachio

import "core:fmt"
import "core:os"

main1 :: proc() {

	exit_code := run("template.txt", os.stdin, os.stdout, os.stderr)
	os.exit(exit_code)
}

run :: proc(path: string, inp, out, err: os.Handle) -> int {

	source, ok := os.read_entire_file(path)
	defer delete(source)
	if !ok {
		fmt.fprintf(err, "Could not read file \"%s\"\n", path)
		return 1
	}
	return 0
}

import vmem "core:mem/virtual"
main :: proc() {

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	source := "{{#tag}}{{name}}some text{{/tag}}"
	parser := create_parser(source, allocator)

	advance(&parser)
	expr, eof := parse_expr(&parser)
	fmt.println(expr_to_string(expr, allocator), eof)
}
