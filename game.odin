package main

import "core:math"
import rl "vendor:raylib"

Game :: struct {
	running: bool,
	time:    f32, // total time elapsed
	tilemap: Tilemap,
	camera:  Camera2D,
}

Camera2D :: struct {
	offset: rl.Vector2,
	zoom:   f32,
}

CAMERA_PAN_SPEED :: 400

game_init :: proc() -> Game {
	g := Game {
		running = true,
		time    = 0,
	}
	g.tilemap = tilemap_init()
	g.camera = camera_init()
	return g
}

camera_init :: proc() -> Camera2D {
	camera_x := f32(MAP_WIDTH * TILE_SIZE) * 0.5
	camera_y := f32(MAP_HEIGHT * TILE_SIZE) * 0.5
	return Camera2D{offset = {camera_x, camera_y}, zoom = 1.0}
}

camera_update :: proc(camera: ^Camera2D, dt: f32) {
	pan := rl.Vector2{0, 0}
	if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {pan.y -= 1}
	if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {pan.y += 1}
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {pan.x -= 1}
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {pan.x += 1}

	if pan.x != 0 || pan.y != 0 {
		len := math.sqrt(pan.x * pan.x + pan.y * pan.y)
		pan.x /= len
		pan.y /= len
		camera.offset.x += pan.x * CAMERA_PAN_SPEED * dt / camera.zoom
		camera.offset.y += pan.y * CAMERA_PAN_SPEED * dt / camera.zoom
	}

	wheel := rl.GetMouseWheelMove()
	if wheel != 0 {
		camera.zoom = math.clamp(camera.zoom + wheel * 0.15, 0.35, 3.0)
	}
}

world_to_screen :: proc(camera: ^Camera2D, wx, wy: f32) -> (f32, f32) {
	screen_x := (wx - camera.offset.x) * camera.zoom + f32(WINDOW_WIDTH) * 0.5
	screen_y := (wy - camera.offset.y) * camera.zoom + f32(WINDOW_HEIGHT) * 0.5
	return screen_x, screen_y
}

screen_to_world :: proc(camera: ^Camera2D, sx, sy: f32) -> (f32, f32) {
	world_x := (sx - f32(WINDOW_WIDTH) * 0.5) / camera.zoom + camera.offset.x
	world_y := (sy - f32(WINDOW_HEIGHT) * 0.5) / camera.zoom + camera.offset.y
	return world_x, world_y
}

game_update :: proc(g: ^Game, dt: f32) {
	g.time += dt

	if rl.IsKeyPressed(.ESCAPE) {
		g.running = false
	}

	camera_update(&g.camera, dt)
}

game_draw :: proc(g: ^Game) {
	tilemap_draw(&g.tilemap, &g.camera)
	fps := rl.GetFPS()
	rl.DrawText(rl.TextFormat("FPS: %i", fps), 10, 36, 20, rl.GREEN)
	rl.DrawText(rl.TextFormat("Time: %.1fs", g.time), 10, 62, 20, rl.GRAY)
	rl.DrawText(rl.TextFormat("Zoom: %2f", g.camera.zoom), 10, 88, 20, rl.GRAY)
}

game_shutdown :: proc(g: ^Game) {
	tilemap_destroy(&g.tilemap)
}

