package main

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
