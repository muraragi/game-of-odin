package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

SCREEN_WIDTH :: 720 + (16 * 30)
SCREEN_HEIGHT :: 640 + (16 * 5)
GRID_SIZE :: 16
PADDING :: 80
COLS :: (SCREEN_WIDTH - PADDING) / GRID_SIZE
ROWS :: (SCREEN_HEIGHT - PADDING) / GRID_SIZE
CELL_NEIGHBOURS :: [8][2]int{{1, 0}, {1, 1}, {0, 1}, {-1, 0}, {-1, -1}, {0, -1}, {-1, 1}, {1, -1}}

Cell_State :: enum {
	DEAD,
	ALIVE,
}

Cell :: struct {
	state:    Cell_State,
	pos:      [2]f32,
	grid_pos: [2]int,
}

Timer :: struct {
	interval:    f32,
	accumulator: f32,
	paused:      bool,
}

create_timer :: proc(interval: f32) -> Timer {
	return Timer{interval = interval, accumulator = 0.0, paused = true}
}

tick_timer :: proc(timer: ^Timer, elapsed: f32) -> bool {
	timer.accumulator += elapsed
	if timer.accumulator > timer.interval {
		timer.accumulator -= timer.interval
		return true
	} else {
		return false
	}
}

get_alive_neighbours_count :: proc(target_cell: ^Cell, cells: ^[COLS * ROWS]Cell) -> int {
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

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Game of Life")
	rl.SetTargetFPS(120)

	cells: [COLS * ROWS]Cell

	for y in 0 ..< ROWS {
		for x in 0 ..< COLS {
			i := COLS * y + x
			cells[i] = Cell {
				state    = .DEAD,
				pos      = {f32(x * GRID_SIZE), f32(y * GRID_SIZE)},
				grid_pos = {int(x), int(y)},
			}
		}
	}

	simulation_timer := create_timer(0.2)
	board_origin := [2]f32{f32(PADDING) / 2, f32(PADDING) / 2}
	board_rect := rl.Rectangle {
		board_origin.x,
		board_origin.y,
		f32(COLS * GRID_SIZE),
		f32(ROWS * GRID_SIZE),
	}

	saved_patterns := parse_saved_patterns()
	defer {
		for &pattern in saved_patterns {
			delete(pattern.offsets)
			delete(pattern.name)
		}
		delete(saved_patterns)
	}

	for !rl.WindowShouldClose() {

		if rl.IsMouseButtonPressed(.LEFT) {
			mouse_pos := rl.GetMousePosition()

			if rl.CheckCollisionPointRec(mouse_pos, board_rect) {
				local_pos := mouse_pos - board_origin
				grid_x := int(local_pos.x / GRID_SIZE)
				grid_y := int(local_pos.y / GRID_SIZE)
				cell_index := COLS * grid_y + grid_x

				cells[cell_index].state = .DEAD if cells[cell_index].state == .ALIVE else .ALIVE
			}
		}

		if !simulation_timer.paused && tick_timer(&simulation_timer, rl.GetFrameTime()) {
			next_cells := cells
			for &cell, index in cells {
				alive_neighbours := get_alive_neighbours_count(&cell, &cells)

				if alive_neighbours < 2 || alive_neighbours >= 4 {
					next_cells[index].state = .DEAD
				} else if alive_neighbours == 3 {
					next_cells[index].state = .ALIVE
				}
			}
			cells = next_cells
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)

		for cell in cells {
			if cell.state == .ALIVE {
				rl.DrawRectangleV(cell.pos + board_origin, GRID_SIZE, rl.BEIGE)
			} else {
				rl.DrawRectangleLines(
					i32(cell.pos.x + board_origin.x),
					i32(cell.pos.y + board_origin.y),
					GRID_SIZE,
					GRID_SIZE,
					rl.BEIGE,
				)
			}
		}

		if rl.GuiButton(
			rl.Rectangle{PADDING / 2, 16, 120, 20},
			rl.GuiIconText(.ICON_PLAYER_PLAY, "RUN SIMULATION"),
		) {
			simulation_timer.paused = !simulation_timer.paused
		}

		rl.EndDrawing()
	}
}
