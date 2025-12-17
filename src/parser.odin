package mustachio

import "base:runtime"
import "core:fmt"

Parser :: struct {
	scanner:        Scanner,
	current_token:  Token,
	previous_token: Token,
	errors:         [dynamic]string,
	section_stack:  Stack,
	allocator:      runtime.Allocator,
}

parser_create :: proc(source: string, allocator := context.allocator) -> Parser {

	p := Parser {
		scanner       = scanner_create(source, allocator),
		errors        = make([dynamic]string, allocator),
		section_stack = create_stack(allocator),
		allocator     = allocator,
	}
	// We need to scan the first token to prime the parser
	advance(&p)
	return p
}

parser_destroy :: proc(p: ^Parser) {

	scanner_destroy(&p.scanner)
	for error in p.errors {
		delete(error)
	}
	delete(p.errors)
	destroy_stack(&p.section_stack)
}

parser_all_exprs :: proc(p: ^Parser) -> []Expr {

	exprs := make([dynamic]Expr, allocator = p.allocator)
	advance(p)
	for {
		expr, eof := parser_next_expr(p)
		if eof { break }
		append(&exprs, expr)
	}
	return exprs[:]
}

parser_next_expr :: proc(p: ^Parser) -> (expr: Expr, eof: bool) {

	switch p.current_token.type {
	case .Empty:
		panic("Token is empty")
	case .Open_Tag:
		expr = parse_tag(p)
	case .Close_Tag:
		report_error(p, "Orphan close tag.")
		// Corrective action: skip to the next token.
		advance(p)
	case .Open_Comment:
		expr = parse_comment(p)
	case .Open_Section:
		expr = parse_section(p, false)
	case .Open_End_Of_Section:
		expr = parse_end_of_section(p)
	case .Open_Inverted_Section:
		expr = parse_section(p, true)
	case .Open_Partial:
		expr = parse_partial(p)
	case .Text:
		expr = parse_text(p)
	case .End_Of_File:
		eof = true
	}
	return
}

@(private = "file")
report_error :: proc(p: ^Parser, msg: string) {

	error_msg := fmt.aprintf("Error: [line %d] %s", p.scanner.line, msg, allocator = p.allocator)
	append(&p.errors, error_msg)
}

@(private = "file")
parse_tag :: proc(p: ^Parser) -> Expr {

	tag: Tag
	// Consume the Open Tag.
	advance(p)
	if p.current_token.type != .Text {
		report_error(p, "Expected a varname in a tag.")
		// Let the parser try to handle that expression.
		return nil
	}
	if !is_varname(p.current_token.lexeme) {
		report_error(p, "Expected a varname in a tag, not text.")
		// Let's keep parsing to catch the close tag.
	}
	tag.varname = p.current_token.lexeme
	// Consume the varname
	advance(p)
	if p.current_token.type != .Close_Tag {
		report_error(p, "Missing closing moustache.")
		// We will pretend there is one.
	} else {
		// Consume the Closing Tag.
		advance(p)
	}
	return tag
}

@(private = "file")
parse_comment :: proc(p: ^Parser) -> Expr {

	comment: Comment
	// Consume the Open Tag.
	advance(p)
	if p.current_token.type != .Text {
		report_error(p, "Expected text in a comment.")
		// consume the closing tag
		advance(p)
		return nil
	}
	comment.content = p.current_token.lexeme
	// Consume the content
	advance(p)
	if p.current_token.type != .Close_Tag {
		report_error(p, "Missing closing moustache.")
		// We will pretend there is one.
		return comment
	} else {
		// Consume the Closing Tag.
		advance(p)
	}
	return comment
}

@(private = "file")
parse_section :: proc(p: ^Parser, inverted: bool) -> Expr {

	section := Section {
		inverted = inverted,
	}
	// Consume the Open Tag.
	advance(p)
	if p.current_token.type != .Text {
		report_error(p, "Expected a varname in a section tag.")
		// Let the parser try to handle that expression.
		return nil
	}
	if !is_varname(p.current_token.lexeme) {
		report_error(p, "Expected a varname in a section tag, not text.")
		// Let's keep parsing to catch the close tag.
	}
	section.varname = p.current_token.lexeme
	// Also remember which section we are in
	stack_push(&p.section_stack, section.varname)
	// Consume the varname
	advance(p)
	if p.current_token.type != .Close_Tag {
		report_error(p, "Missing closing moustache.")
	} else {
		// Consume the Closing Tag.
		advance(p)
	}
	// Parse the section content
	content := make([dynamic]Expr, p.allocator)
	for {
		expr, eof := parser_next_expr(p)
		if eof {
			report_error(p, "Reached end of stream while parsing a section.")
			return nil
		}
		if end_of_section, ok := expr.(End_Of_Section); ok {
			// Check this is the right one
			// We know the stack can't be empty since we just pushed the section name.
			if stack_peek(p.section_stack) != end_of_section.varname {
				report_error(p, "Mismatch between the head and end of section varnames.")
				// Just pretend it's the right one for now.
			}
			stack_pop(&p.section_stack)
			break
		} else {
			append(&content, expr)
		}
	}
	section.content = content[:]

	return section
}

@(private = "file")
parse_end_of_section :: proc(p: ^Parser) -> Expr {

	end_of_section: End_Of_Section
	// Consume the Open Tag.
	advance(p)
	if p.current_token.type != .Text {
		report_error(p, "Expected a varname in a end-of-section tag.")
		// Let the parser try to handle that expression.
		return nil
	}
	if !is_varname(p.current_token.lexeme) {
		report_error(p, "Expected a varname in an end-of-section tag, not text.")
		// Let's keep parsing to catch the close tag.
	}
	end_of_section.varname = p.current_token.lexeme
	// Consume the varname
	advance(p)
	if p.current_token.type != .Close_Tag {
		report_error(p, "Missing closing moustache.")
	} else {
		// Consume the Closing Tag.
		advance(p)
	}

	return end_of_section
}

@(private = "file")
parse_partial :: proc(p: ^Parser) -> Expr {

	partial: Partial
	// Consume the Open Tag.
	advance(p)
	if p.current_token.type != .Text {
		report_error(p, "Expected a varname in a partial.")
		// Let the parser try to handle that expression.
		return nil
	}
	if !is_varname(p.current_token.lexeme) {
		report_error(p, "Expected a varname in a partial, not text.")
		// Let's keep parsing to catch the close tag.
	}
	partial.varname = p.current_token.lexeme
	// Consume the varname
	advance(p)
	if p.current_token.type != .Close_Tag {
		report_error(p, "Missing closing moustache.")
		// We will pretend there is one.
	} else {
		// Consume the Closing Tag.
		advance(p)
	}
	return partial
}

@(private = "file")
parse_text :: proc(p: ^Parser) -> Expr {

	expr := Text {
		content = p.current_token.lexeme,
	}
	// Consume the Text.
	advance(p)
	return expr
}

@(private = "file")
advance :: proc(p: ^Parser) {

	if p.current_token.type == .End_Of_File { return }
	p.previous_token = p.current_token
	p.current_token = scanner_next_token(&p.scanner)
}

@(private = "file")
is_varname :: proc(str: string) -> bool {

	first := true
	for letter in str {
		if first {
			first = false
			if !is_alpha(letter) { return false }
		} else {
			if !(is_alpha(letter) || is_digit(letter) || is_special(letter)) { return false }
		}
	}
	return true
}

@(private = "file")
is_alpha :: proc(r: rune) -> bool {

	return (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z')
}

@(private = "file")
is_digit :: proc(r: rune) -> bool {

	return r >= '0' && r <= '9'
}

@(private = "file")
is_special :: proc(r: rune) -> bool {

	return r == '_'
}
