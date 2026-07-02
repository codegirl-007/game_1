package main

import rl "vendor:raylib"

Tilemap :: struct {
	width:  int,
	height: int,
	tiles:  []u8,
}

tilemap_init :: proc() -> Tilemap {
	return Tilemap {
		width = MAP_WIDTH,
		height = MAP_HEIGHT,
		tiles = make([]u8, MAP_WIDTH * MAP_HEIGHT),
	}
}

tilemap_destroy :: proc(tilemap: ^Tilemap) {
	delete(tilemap.tiles)
}

tile_in_bounds :: proc(tilemap: ^Tilemap, x: int, y: int) -> bool {
	// learning from another game, this will become handy
	return x >= 0 && x < tilemap.width && y >= 0 && y < tilemap.height
}

tile_index :: proc(tilemap: ^Tilemap, x, y: int) -> int {
	return y * tilemap.width + x
}

tile_color :: proc(type_id: u8) -> rl.Color {
	// going to make this a table at some point but for now, we do this
	switch type_id {
	case 0:
		return {72, 112, 68, 255}
	case:
		return rl.MAGENTA
	}
}

tilemap_draw :: proc(tilemap: ^Tilemap, camera: ^Camera2D) {
	tile_px := f32(TILE_SIZE) * camera.zoom

	for y in 0 ..< tilemap.height {
		for x in 0 ..< tilemap.width {
			wx := f32(x * TILE_SIZE)
			wy := f32(y * TILE_SIZE)
			sx, sy := world_to_screen(camera, wx, wy)

			if sx + tile_px < 0 || sy + tile_px < 0 {continue}
			if sx > f32(WINDOW_WIDTH) || sy > f32(WINDOW_HEIGHT) {continue}

			index := tile_index(tilemap, x, y)
			color := tile_color(tilemap.tiles[index])

			rl.DrawRectangle(i32(sx), i32(sy), i32(tile_px), i32(tile_px), color)
			rl.DrawRectangleLines(i32(sx), i32(sy), i32(tile_px), i32(tile_px), {40, 50, 38, 255})
		}
	}
}

