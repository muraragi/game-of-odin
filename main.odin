package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

SCREEN_WIDTH :: 720 + (16 * 30)
SCREEN_HEIGHT :: 640 + (16 * 5)

get_alive_neighbours_count :: proc(target_cell: ^Cell, cells: ^Board) -> int {
	neighbours_count: int = 0

	for neighbour in CELL_NEIGHBOURS {
		neighbour_grid_pos := target_cell.grid_pos + neighbour
		if neighbour_grid_pos.x < 0 ||
		   neighbour_grid_pos.x >= int(COLS) ||
		   neighbour_grid_pos.y < 0 ||
		   neighbour_grid_pos.y >= int(ROWS) {
			continue
		}

		cell_index := COLS * neighbour_grid_pos.y + neighbour_grid_pos.x
		if cells[cell_index].state == .ALIVE {
			neighbours_count += 1
		}
	}

	return neighbours_count
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

		rl.EndDrawing()
	}
}

run_simulation_button :: proc(text: cstring, icon: rl.GuiIconName) -> bool {
	return rl.GuiButton(rl.Rectangle{PADDING / 2, 16, 160, 20}, rl.GuiIconText(icon, text))
}
