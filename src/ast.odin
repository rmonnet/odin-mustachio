package mustachio

import "base:runtime"
import "core:fmt"
import "core:strings"

Expr :: union {
	Text,
	Tag,
	Comment,
	Section,
	End_Of_Section,
	Partial,
}

Text :: struct {
	content: string,
}

Tag :: struct {
	varname: string,
	env:     Env,
}

Comment :: struct {
	content: string,
}

Section :: struct {
	varname:  string,
	inverted: bool,
	content:  []Expr,
}

Partial :: struct {
	varname: string,
}

// Only use that tag as a marker
End_Of_Section :: struct {
	varname: string,
}

expr_to_string :: proc(e: Expr, allocator: runtime.Allocator) -> string {

	output: string
	switch expr in e {
	case nil:
		output = "nil"
	case Text:
		output = fmt.aprintf("Text{{%s}}", expr.content, allocator = allocator)
	case Tag:
		output = fmt.aprintf("Tag{{%s}}", expr.varname, allocator = allocator)
	case Comment:
		output = fmt.aprintf("Comment{{%s}}", expr.content, allocator = allocator)
	case Section:
		content_as_str := exprs_to_string(expr.content, allocator)
		inverted := expr.inverted ? "(inverted)" : ""
		output = fmt.aprintf(
			"Section{{%s%s %s}}",
			expr.varname,
			inverted,
			content_as_str,
			allocator = allocator,
		)
	case Partial:
		output = fmt.aprintf("Partial{{%s}}", expr.varname, allocator = allocator)
	case End_Of_Section:
		output = fmt.aprintf("End_Of_Section{{%s}}}", expr.varname, allocator = allocator)
	}
	return output
}

exprs_to_string :: proc(es: []Expr, allocator: runtime.Allocator) -> string {

	content := make([]string, len(es), allocator)
	for subexpr, i in es {
		content[i] = expr_to_string(subexpr, allocator)
	}
	content_as_str := strings.join(content, ", ", allocator = allocator)
	return fmt.aprintf("[%s]", content_as_str, allocator = allocator)
}
