package main

SCREEN_WIDTH :: 720 + (16 * 30)
SCREEN_HEIGHT :: 640 + (16 * 5)
PADDING_X :: 80
PADDING_Y :: 116
GRID_SIZE :: 16

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
