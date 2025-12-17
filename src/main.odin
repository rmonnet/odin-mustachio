package mustachio

import "core:fmt"
import vmem "core:mem/virtual"
import "core:os"

main1 :: proc() {

	if len(os.args) != 2 {
		fmt.eprintf("Usage: mustachio <template filename>")
		os.exit(1)
	}

	exit_code := run(os.args[1], os.stdin, os.stdout, os.stderr)
	os.exit(exit_code)
}

run :: proc(path: string, inp, out, err: os.Handle) -> int {

	source, ok := os.read_entire_file(path)
	defer delete(source)
	if !ok {
		fmt.fprintf(err, "Could not read file \"%s\"\n", path)
		return 1
	}

	arena: vmem.Arena
	allocator := arena_init(&arena)
	defer vmem.arena_destroy(&arena)

	parser := parser_create(string(source), allocator)
	exprs := parser_all_exprs(&parser)

	if len(parser.errors) > 0 {
		fmt.fprintf(err, "Error in template %s:\n", path)
		for error in parser.errors {
			fmt.fprintln(err, error)
		}
		return 1
	}

	for expr in exprs {
		fmt.fprintln(out, expr_to_string(expr, allocator))
	}
	return 0
}

import "core:encoding/json"
main :: proc() {

	json_data := load_json()
	defer json.destroy_value(json_data)
	age, ok := lookup(json_data, "age")
	age_as_str := primitive_to_string(age)
	fmt.println(age, ok, typeid_of(type_of(age)), age_as_str)
}
