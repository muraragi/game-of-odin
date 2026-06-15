package main

import rl "vendor:raylib"

GRID_SIZE :: 16
PADDING :: 80
COLS :: (SCREEN_WIDTH - PADDING) / GRID_SIZE
ROWS :: (SCREEN_HEIGHT - PADDING) / GRID_SIZE
CELL_NEIGHBOURS :: [8][2]int{{1, 0}, {1, 1}, {0, 1}, {-1, 0}, {-1, -1}, {0, -1}, {-1, 1}, {1, -1}}
BOARD_ORIGIN :: [2]f32{f32(PADDING) / 2, f32(PADDING) / 2}
BOARD_RECT :: rl.Rectangle {
	BOARD_ORIGIN.x,
	BOARD_ORIGIN.y,
	f32(COLS * GRID_SIZE),
	f32(ROWS * GRID_SIZE),
}

Cell_State :: enum {
	DEAD,
	ALIVE,
}

Cell :: struct {
	state:    Cell_State,
	pos:      [2]f32,
	grid_pos: [2]int,
}

Board :: [COLS * ROWS]Cell

create_board :: proc() -> Board {
	board: Board

	for y in 0 ..< ROWS {
		for x in 0 ..< COLS {
			i := COLS * y + x
			board[i] = Cell {
				state    = .DEAD,
				pos      = {f32(x * GRID_SIZE), f32(y * GRID_SIZE)},
				grid_pos = {int(x), int(y)},
			}
		}
	}

	return board
}

handle_input :: proc(board: ^Board) {
	if rl.IsMouseButtonPressed(.LEFT) {
		mouse_pos := rl.GetMousePosition()

		if rl.CheckCollisionPointRec(mouse_pos, BOARD_RECT) {
			local_pos := mouse_pos - BOARD_ORIGIN
			grid_x := int(local_pos.x / GRID_SIZE)
			grid_y := int(local_pos.y / GRID_SIZE)
			cell_index := COLS * grid_y + grid_x

			board[cell_index].state = .DEAD if board[cell_index].state == .ALIVE else .ALIVE
		}
	}
}

run_simulation :: proc(simulation_timer: ^Timer, board: Board) -> Board {
	next_board := board

	if !simulation_timer.paused && tick_timer(simulation_timer, rl.GetFrameTime()) {
		for &cell, index in next_board {
			alive_neighbours := get_alive_neighbours_count(&cell, &next_board)

			if alive_neighbours < 2 || alive_neighbours >= 4 {
				next_board[index].state = .DEAD
			} else if alive_neighbours == 3 {
				next_board[index].state = .ALIVE
			}
		}
	}

	return next_board
}

draw_board :: proc(board: ^Board) {
	for cell in board {
		if cell.state == .ALIVE {
			rl.DrawRectangleV(cell.pos + BOARD_ORIGIN, GRID_SIZE, rl.BEIGE)
		} else {
			rl.DrawRectangleLines(
				i32(cell.pos.x + BOARD_ORIGIN.x),
				i32(cell.pos.y + BOARD_ORIGIN.y),
				GRID_SIZE,
				GRID_SIZE,
				rl.BEIGE,
			)
		}
	}
}
