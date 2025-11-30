package mustachio

import "base:runtime"
import "core:unicode/utf8"
Token :: struct {
	type:   TokenType,
	lexeme: string,
	line:   int,
}

destroy_token :: proc(t: ^Token) {

	delete(t.lexeme)
}

TokenType :: enum {
	Error,
	Open_Tag,
	Close_Tag,
	Open_Comment,
	Open_Section,
	Open_End_Of_Section,
	Open_Inverted_Section,
	Open_Partial,
	Text,
	End_Of_File,
}

Scanner :: struct {
	source:    []rune,
	start:     int,
	current:   int,
	line:      int,
	allocator: runtime.Allocator,
}

create_scanner :: proc(source: string, allocator := context.allocator) -> Scanner {

	source_as_runes := utf8.string_to_runes(source, allocator)
	return Scanner {
		source = source_as_runes,
		start = 0,
		current = 0,
		line = 1,
		allocator = allocator,
	}
}

destroy_scanner :: proc(s: ^Scanner) {

	delete(s.source)
}

next_token :: proc(s: ^Scanner) -> Token {

	s.start = s.current
	if is_at_end(s^) { return make_token(s^, .End_Of_File) }

	c := advance(s)
	switch {
	case c == '{' && match(s, '{'):
		switch {
		case match(s, '!'):
			return make_token(s^, .Open_Comment)
		case match(s, '#'):
			return make_token(s^, .Open_Section)
		case match(s, '^'):
			return make_token(s^, .Open_Inverted_Section)
		case match(s, '>'):
			return make_token(s^, .Open_Partial)
		case match(s, '/'):
			return make_token(s^, .Open_End_Of_Section)
		case:
			return make_token(s^, .Open_Tag)
		}
	case c == '}' && match(s, '}'):
		return make_token(s^, .Close_Tag)
	}
	return text(s)
}

@(private = "file")
text :: proc(s: ^Scanner) -> Token {

	for !is_next(s^, '{', '{') && !is_next(s^, '}', '}') && !is_at_end(s^) {
		if peek(s^) == '\n' { s.line += 1 }
		advance(s)
	}
	return make_token(s^, .Text)
}

@(private = "file")
is_digit :: proc(c: byte) -> bool {
	return c >= '0' && c <= '9'
}

@(private = "file")
is_alpha :: proc(c: byte) -> bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

@(private = "file")
is_at_end :: proc(s: Scanner) -> bool {

	return s.current >= len(s.source)
}

@(private = "file")
make_token :: proc(s: Scanner, type: TokenType) -> Token {

	lexeme := utf8.runes_to_string(s.source[s.start:s.current], s.allocator)
	return Token{type = type, lexeme = lexeme, line = s.line}
}

@(private = "file")
advance :: proc(s: ^Scanner, by := 1) -> rune {

	s.current += by
	return s.source[s.current - by]
}

@(private = "file")
// match is a shortcut for 'if peek then advance'.
// It returns if the peek was successful.
match :: proc(s: ^Scanner, want: rune) -> bool {

	if is_at_end(s^) { return false }
	if s.source[s.current] != want { return false }
	s.current += 1
	return true
}

@(private = "file")
// is_next peeks multiple values and check if they match what we want.
is_next :: proc(s: Scanner, want: ..rune) -> bool {

	pos := s.current
	for char in want {
		if pos >= len(s.source) { return false }
		if s.source[pos] != char { return false }
		pos += 1
	}
	return true
}
/*
@(private = "file")
skip_whitespace :: proc() {
	// We will handle comments with whitespace for convenience.
	for {
		if is_at_end() {
			return
		}
		c := peek()
		switch c {
		case ' ', '\r', '\t':
			advance()
		case '\n':
			scanner.line += 1
			advance()
		case '/':
			if peek_next() == '/' {
				for peek() != '\n' && !is_at_end() { advance() }
			}
		case:
			return
		}
	}
}
*/

@(private = "file")
peek :: proc(s: Scanner, ahead := 0) -> rune {

	pos := s.current + ahead
	if (pos) >= len(s.source) { return 0 }
	return s.source[pos]
}

@(private = "file")
error_token :: proc(s: Scanner, message: string) -> Token {

	return Token{type = .Error, lexeme = message, line = s.line}
}
