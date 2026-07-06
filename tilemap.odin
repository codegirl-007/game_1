package main

import rl "vendor:raylib"

Tilemap :: struct {
	width:  int,
	height: int,
	tiles:  []u8,
}

tilemap_init :: proc() -> Tilemap {
	tm := Tilemap {
		width  = MAP_WIDTH,
		height = MAP_HEIGHT,
		tiles  = make([]u8, MAP_WIDTH * MAP_HEIGHT),
	}
	// test wall
	// Horizontal mud strip (expensive, cost 20 per step)
	for y in 8 ..< 18 {
		tm.tiles[tile_index(&tm, 5, y)] = 3 // mud
	}
	// Road detour (cheap, cost 1 per step) — goes right, down, left
	for x in 5 ..< 12 {
		tm.tiles[tile_index(&tm, x, 8)] = 2 // road top
		tm.tiles[tile_index(&tm, x, 18)] = 2 // road bottom
	}
	for y in 8 ..< 19 {
		tm.tiles[tile_index(&tm, 11, y)] = 2 // road right side
	}
	return tm
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
	case 1:
		return {90, 90, 95, 255} // wall — gray
	case 2:
		return {160, 140, 100, 255} // road — tan/brown
	case 3:
		return {120, 100, 70, 255} // mud — darker brown
	case:
		return rl.MAGENTA
	}
}

tilemap_draw_selection :: proc(tilemap: ^Tilemap, cam: ^Camera2D, selection: ^Selection) {
	if !selection.active {
		return
	}

	wx := f32(selection.tile.x * TILE_SIZE)
	wy := f32(selection.tile.y * TILE_SIZE)
	sx, sy := world_to_screen(cam, wx, wy)
	tile_px := f32(TILE_SIZE) * cam.zoom

	highlight := rl.Color{255, 220, 80, 120}
	rl.DrawRectangle(i32(sx), i32(sy), i32(tile_px), i32(tile_px), highlight)
	rl.DrawRectangleLines(i32(sx), i32(sy), i32(tile_px), i32(tile_px), rl.GOLD)
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


tile_walkable :: proc(tilemap: ^Tilemap, x, y: int) -> bool {
	if !tile_in_bounds(tilemap, x, y) {return false}
	idx := tile_index(tilemap, x, y)

	return tilemap.tiles[idx] != 1
}

tile_cost :: proc(tm: ^Tilemap, x, y: int) -> int {
	if !tile_walkable(tm, x, y) {
		return max_path_int
	}
	switch tm.tiles[tile_index(tm, x, y)] {
	case 0:
		return 10
	case 2:
		return 1
	case 3:
		return 20
	case:
		return 10
	}
}

