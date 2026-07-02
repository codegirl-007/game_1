package main

import rl "vendor:raylib"

Entity :: distinct u32

Entity_World :: struct {
	count:       int,
	active:      [MAX_ENTITIES]bool,
	position:    [MAX_ENTITIES]Tile_Coord,
	color:       [MAX_ENTITIES]rl.Color,
	is_colonist: [MAX_ENTITIES]bool,
}

entity_world_init :: proc() -> Entity_World {
	return Entity_World{}
}

entity_spawn_colonist :: proc(ew: ^Entity_World, pos: Tile_Coord) -> Entity {
	for i in 0 ..< MAX_ENTITIES {
		if !ew.active[i] {
			ew.active[i] = true
			ew.position[i] = pos
			ew.color[i] = {80, 140, 220, 225}
			ew.is_colonist[i] = true
			ew.count += 1
			return Entity(u32(i + 1))
		}
	}

	return INVALID_ENTITY
}

entity_index :: proc(e: Entity) -> int {
	return int(u32(e) - 1)
}

entity_draw :: proc(ew: ^Entity_World, camera: ^Camera2D) {
	for i in 0 ..< MAX_ENTITIES {
		if !ew.active[i] || !ew.is_colonist[i] {
			continue
		}

		pos := ew.position[i]
		wx := f32(pos.x * TILE_SIZE) + f32(TILE_SIZE) * 0.5
		wy := f32(pos.y * TILE_SIZE) + f32(TILE_SIZE) * 0.5
		sx, sy := world_to_screen(camera, wx, wy)
		radius := f32(TILE_SIZE) * 0.3 * camera.zoom

		rl.DrawCircle(i32(sx), i32(sy), radius, ew.color[i])
		rl.DrawCircleLines(i32(sx), i32(sy), radius, rl.WHITE)
	}
}

