package main

import "core:fmt"
import "core:mem"
import "core:strings"
import rl "vendor:raylib"

SCREEN_WIDTH :: 720 + (16 * 30)
SCREEN_HEIGHT :: 640 + (16 * 5)
PADDING_X :: 80
PADDING_Y :: 116
GRID_SIZE :: 16

main :: proc() {
	// ========== MEMORY DEBUG ==========
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- leaked %v bytes at %v\n", entry.size, entry.location)
				}
			}

			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v bad frees ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- bad free of %p at %v\n", entry.memory, entry.location)
				}
			}

			if len(track.allocation_map) == 0 && len(track.bad_free_array) == 0 {
				fmt.eprintln("No memory leaks detected")
			}

			mem.tracking_allocator_destroy(&track)
		}
	}
	// ===================================

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Game of Life")
	rl.SetTargetFPS(120)

	saved_patterns := parse_saved_patterns()
	defer {
		for &pattern in saved_patterns {
			delete(pattern.offsets)
			delete(pattern.name)
		}
		delete(saved_patterns)
	}

	board: Board = create_board()

	simulation_timer := create_timer(0.2)

	scroll_state := rl.Vector2{}

	for !rl.WindowShouldClose() {
		handle_input(&board)
		board = run_simulation(&simulation_timer, board)

		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)

		draw_board(&board)

		if simulation_timer.paused &&
		   run_simulation_button(cstring("RUN SIMULATION"), .ICON_PLAYER_PLAY) {
			simulation_timer.paused = false
		} else if !simulation_timer.paused &&
		   run_simulation_button(cstring("PAUSE SIMULATION"), .ICON_PLAYER_PAUSE) {
			simulation_timer.paused = true
		}

		draw_saved_patterns_ui(&saved_patterns, &scroll_state)

		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}

PATTERNS_X :: f32(PADDING_X / 2)
PATTERNS_Y :: f32(SCREEN_HEIGHT - 64)
PATTERNS_WIDTH :: f32(SCREEN_WIDTH - PADDING_X)
PATTERNS_HEIGHT :: f32(32)
PATTERNS_BOUND_RECT :: rl.Rectangle{PATTERNS_X, PATTERNS_Y, PATTERNS_WIDTH, PATTERNS_HEIGHT}

PATTERN_BUTTON_WIDTH :: f32(140)
PATTERN_BUTTON_HEIGHT :: f32(20)
PATTERN_BUTTONS_GAP :: f32(8)

draw_saved_patterns_ui :: proc(saved_patters: ^[dynamic]Pattern, scroll_state: ^rl.Vector2) {
	total_buttons := f32(len(saved_patters))
	total_content_width := f32(total_buttons * (PATTERN_BUTTON_WIDTH + PATTERN_BUTTONS_GAP))
	content_rect := rl.Rectangle{PATTERNS_X, PATTERNS_Y, total_content_width, PATTERNS_HEIGHT}
	view: rl.Rectangle

	rl.GuiScrollPanel(PATTERNS_BOUND_RECT, nil, content_rect, scroll_state, &view)

	rl.BeginScissorMode(i32(view.x), i32(view.y), i32(view.width), i32(view.height))
	for pattern, i in saved_patters {
		button_x :=
			PATTERNS_X + scroll_state.x + (f32(i) * (PATTERN_BUTTON_WIDTH + PATTERN_BUTTONS_GAP))

		if rl.GuiButton(
			rl.Rectangle{button_x, PATTERNS_Y, PATTERN_BUTTON_WIDTH, PATTERN_BUTTON_HEIGHT},
			strings.clone_to_cstring(pattern.name, context.temp_allocator),
		) {
			fmt.printfln("pattern pressed", pattern.name)
		}
	}
	rl.EndScissorMode()
}

run_simulation_button :: proc(text: cstring, icon: rl.GuiIconName) -> bool {
	return rl.GuiButton(
		rl.Rectangle{PADDING_X / 2, PADDING_Y / 2 - 32, 160, 20},
		rl.GuiIconText(icon, text),
	)
}
