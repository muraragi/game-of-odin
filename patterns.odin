// pipilabu gerard way sahur big tripple tea brr brr patapim shto dame dame tabadu bibble joppini juzeppini jeveviyan de cherche ju lamour mon plaisir chiiikawa abvgde hehe popiii popi popi poooo popipo winx popik kapuchino mimimi
package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

NAME_SPLITTER :: "|"
OFFSET_SPLITTER :: ";"
VALUE_SPLITTER :: ","

Offset :: [2]int

Pattern :: struct {
	offsets: [dynamic]Offset,
	name:    string,
}

parse_saved_patterns :: proc() -> [dynamic]Pattern {

	file_content, err := os.read_entire_file("patterns.txt", context.allocator)
	defer delete(file_content)

	if err != nil {
		panic("Couldn't read the patterns file")
	}

	text := string(file_content)
	patterns := make([dynamic]Pattern)

	for line in strings.split_lines_iterator(&text) {
		pattern_name_text, _, pattern_offsets := strings.partition(line, NAME_SPLITTER)

		pattern_name := strings.clone(pattern_name_text)

		parsed_offsets := make([dynamic]Offset)

		for offset in strings.split_iterator(&pattern_offsets, OFFSET_SPLITTER) {
			x_text, _, y_text := strings.partition(offset, VALUE_SPLITTER)

			parsed_offset: Offset
			x, x_ok := strconv.parse_int(x_text)
			y, y_ok := strconv.parse_int(y_text)

			if !x_ok || !y_ok {
				message := fmt.aprintf("Failed to parse offset %q", offset)
				panic(message)
			}

			parsed_offset.x = x
			parsed_offset.y = y

			append(&parsed_offsets, parsed_offset)
		}

		append(&patterns, Pattern{name = pattern_name, offsets = parsed_offsets})
	}

	return patterns
}
