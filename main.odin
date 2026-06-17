package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

Game_State :: struct {
	simulation_timer:      Timer,
	board:                 Board,
	selected_pattern:      ^Pattern,
	patterns_scroll_state: rl.Vector2,
}

Resources :: struct {
	saved_patterns: [dynamic]Pattern,
}

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

	resources := Resources {
		saved_patterns = parse_saved_patterns(),
	}
	defer {
		for &pattern in resources.saved_patterns {
			delete(pattern.offsets)
			delete(pattern.name)
		}
		delete(resources.saved_patterns)
	}

	game_state := Game_State {
		board            = create_board(),
		simulation_timer = create_timer(0.2),
		selected_pattern = &resources.saved_patterns[0],
	}

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)

		update(&game_state)
		draw(&game_state, &resources)

		rl.EndDrawing()
		free_all(context.temp_allocator)
	}
}

update :: proc(state: ^Game_State) {
	handle_input(state)
	run_simulation(state)
}

draw :: proc(state: ^Game_State, resources: ^Resources) {
	draw_board(&state.board)
	draw_ui(state, resources)
}
