package main

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	game := game_init()
	defer game_shutdown(&game)

	for game.running && !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()

		dt := rl.GetFrameTime()
		game_update(&game, dt)

		rl.ClearBackground({30, 33, 40, 255})
		game_draw(&game)
	}
}

