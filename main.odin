package main

import rl "vendor:raylib"

SCREEN_WIDTH :: 720 + (16 * 10)
SCREEN_HEIGHT :: 640 + 100
GRID_SIZE :: 16
COLS :: SCREEN_WIDTH / GRID_SIZE
ROWS :: SCREEN_HEIGHT / GRID_SIZE
CELL_NEIGHBOURS :: [8][2]i32{{1, 0}, {1, 1}, {0, 1}, {-1, 0}, {-1, -1}, {0, -1}, {-1, 1}, {1, -1}}

Cell_State :: enum {
	DEAD,
	ALIVE,
}

Cell :: struct {
	state:    Cell_State,
	pos:      [2]f32,
	grid_pos: [2]i32,
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

get_alive_neighbours_count :: proc(target_cell: ^Cell, cells: ^[COLS * ROWS]Cell) -> i32 {
	neighbours_count: i32 = 0

	for neighbour in CELL_NEIGHBOURS {
		neighbour_grid_pos := target_cell.grid_pos + neighbour
		if neighbour_grid_pos.x < 0 ||
		   neighbour_grid_pos.x >= i32(COLS) ||
		   neighbour_grid_pos.y < 0 ||
		   neighbour_grid_pos.y >= i32(ROWS) {
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
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Game of Life")
	rl.SetTargetFPS(120)

	cells: [COLS * ROWS]Cell

	for y in 0 ..< ROWS {
		for x in 0 ..< COLS {
			i := COLS * y + x
			cells[i] = Cell {
				state    = .DEAD,
				pos      = {f32(x * GRID_SIZE), f32(y * GRID_SIZE)},
				grid_pos = {i32(x), i32(y)},
			}
		}
	}

	simulation_timer := create_timer(0.2)
	for !rl.WindowShouldClose() {

		if rl.IsMouseButtonPressed(.LEFT) {
			mouse_pos := rl.GetMousePosition()
			grid_x := i32(mouse_pos.x / GRID_SIZE)
			grid_y := i32(mouse_pos.y / GRID_SIZE)
			cell_index := COLS * grid_y + grid_x

			cells[cell_index].state = .DEAD if cells[cell_index].state == .ALIVE else .ALIVE
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
				rl.DrawRectangleV(cell.pos, GRID_SIZE, rl.BEIGE)
			} else {
				rl.DrawRectangleLines(
					i32(cell.pos.x),
					i32(cell.pos.y),
					GRID_SIZE,
					GRID_SIZE,
					rl.BEIGE,
				)
			}
		}

		if rl.GuiButton(
			rl.Rectangle{24, 24, 120, 30},
			rl.GuiIconText(.ICON_PLAYER_PLAY, "RUN SIMULATION"),
		) {
			simulation_timer.paused = !simulation_timer.paused
		}

		rl.EndDrawing()
	}
}
