package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

PATTERNS_X :: f32(PADDING_X / 2)
PATTERNS_Y :: f32(SCREEN_HEIGHT - 64)
PATTERNS_WIDTH :: f32(SCREEN_WIDTH - PADDING_X)
PATTERNS_HEIGHT :: f32(32)
PATTERNS_BOUND_RECT :: rl.Rectangle{PATTERNS_X, PATTERNS_Y, PATTERNS_WIDTH, PATTERNS_HEIGHT}

PATTERN_BUTTON_WIDTH :: f32(140)
PATTERN_BUTTON_HEIGHT :: f32(20)
PATTERN_BUTTONS_GAP :: f32(8)

draw_saved_patterns_ui :: proc(
	saved_patters: ^[dynamic]Pattern,
	state: ^Game_State
) {
	total_buttons := f32(len(saved_patters))
	total_content_width := f32(total_buttons * (PATTERN_BUTTON_WIDTH + PATTERN_BUTTONS_GAP))
	content_rect := rl.Rectangle{PATTERNS_X, PATTERNS_Y, total_content_width, PATTERNS_HEIGHT}
	view: rl.Rectangle

	rl.GuiScrollPanel(PATTERNS_BOUND_RECT, nil, content_rect, &state.patterns_scroll_state, &view)

	rl.BeginScissorMode(i32(view.x), i32(view.y), i32(view.width), i32(view.height))
	for pattern, i in saved_patters {
		button_x :=
			PATTERNS_X + state.patterns_scroll_state.x + (f32(i) * (PATTERN_BUTTON_WIDTH + PATTERN_BUTTONS_GAP))

		if rl.GuiButton(
			rl.Rectangle{button_x, PATTERNS_Y, PATTERN_BUTTON_WIDTH, PATTERN_BUTTON_HEIGHT},
			strings.clone_to_cstring(pattern.name, context.temp_allocator),
		) {
			state.selected_pattern = pattern
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

draw_ui :: proc(state: ^Game_State, resources: ^Resources) {
	if state.simulation_timer.paused &&
	   run_simulation_button(cstring("RUN SIMULATION"), .ICON_PLAYER_PLAY) {
		state.simulation_timer.paused = false
	} else if !state.simulation_timer.paused &&
	   run_simulation_button(cstring("PAUSE SIMULATION"), .ICON_PLAYER_PAUSE) {
		state.simulation_timer.paused = true
	}

	draw_saved_patterns_ui(
		&resources.saved_patterns,
		state
	)
}
