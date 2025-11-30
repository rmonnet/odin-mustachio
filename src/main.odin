package mustachio

import "core:fmt"
import "core:os"

main :: proc() {

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
