package main

import "core:os"
import "core:fmt"
import "core:bufio"
import "core:bytes"
import "core:strings"
import "core:path/filepath"

// NOTE(cya): only works with LF and CRLF lines (not CR)
main :: proc() {
	switch len(os.args) {
	case 1:
		trim_lines_from_stdin()
	case 2:
		trim_lines_from_file(os.args[1])
	case:
		fmt.printfln("usage: %v [filename?]", filepath.base(os.args[0]))
	}
}

trim_lines_from_stdin :: proc() {
	s: bufio.Scanner
	bufio.scanner_init(&s, os.stream_from_handle(os.stdin))
	s.split = scan_lines

	line_ending: string
	for {
		ok := bufio.scanner_scan(&s)
		if !ok {
			break
		}

		line := bufio.scanner_text(&s)
		if line_ending == "" {
			line_ending = infer_line_ending(line)
		}

		fmt.print(strings.trim_right_space(line), line_ending, sep = "")
	}
}

scan_lines :: proc(data: []byte, at_eof: bool) -> (
	advance: int, token: []byte, err: bufio.Scanner_Error, final_token: bool
) {
	if at_eof && len(data) == 0 {
		return
	}

	if i := bytes.index_byte(data, '\n'); i >= 0 {
		advance = i + 1
		token = data[0:i]
	} else if at_eof {
		advance = len(data)
		token = data
	}

	return
}

trim_lines_from_file :: proc(filename: string) {
	data, ferr := os.read_entire_file_or_err(filename)
	if ferr != nil {
		os.print_error(os.stderr, ferr, "couldn't read file")
		return
	}

	b: strings.Builder
	strings.builder_init(&b, 0, len(data))

	line_ending: string
	it := string(data)
	for line in split_lines_iterator(&it) {
		if line_ending == "" {
			line_ending = infer_line_ending(line)
		}

		strings.write_string(&b, strings.trim_right_space(line))
		strings.write_string(&b, line_ending)
	}

	data = transmute([]u8)strings.to_string(b)
	ferr = os.write_entire_file_or_err(filename, data)
	if ferr != nil {
		os.print_error(os.stderr, ferr, "couldn't write to file")
		return
	}
}

split_lines_iterator :: proc(s: ^string) -> (line: string, ok: bool) {
	sep :: "\n"
	line = strings.split_iterator(s, sep) or_return
	return line, true
}

infer_line_ending :: proc(line: string) -> string {
	return strings.ends_with(line, "\r") ? "\r\n" : "\n"
}
