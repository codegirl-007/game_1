package main

import "core:math"
import rl "vendor:raylib"

Entity :: distinct u32

Entity_World :: struct {
	count:           int,
	active:          [MAX_ENTITIES]bool,
	position:        [MAX_ENTITIES]Tile_Coord,
	color:           [MAX_ENTITIES]rl.Color,
	is_colonist:     [MAX_ENTITIES]bool,
	move_state:      [MAX_ENTITIES]Move_State,
	move_target:     [MAX_ENTITIES]Tile_Coord,
	visual_position: [MAX_ENTITIES]rl.Vector2,
	path:            [MAX_ENTITIES]Path,
	path_index:      [MAX_ENTITIES]int,
}

Move_State :: enum {
	Idle,
	Moving,
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
			ew.visual_position[i] = tile_center_world(pos)
			ew.move_state[i] = .Idle
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

		vp := ew.visual_position[i]
		sx, sy := world_to_screen(camera, vp.x, vp.y)
		radius := f32(TILE_SIZE) * 0.3 * camera.zoom

		rl.DrawCircle(i32(sx), i32(sy), radius, ew.color[i])
		rl.DrawCircleLines(i32(sx), i32(sy), radius, rl.WHITE)
	}
}

tile_center_world :: proc(t: Tile_Coord) -> rl.Vector2 {
	return rl.Vector2 {
		f32(t.x * TILE_SIZE) + f32(TILE_SIZE) * 0.5,
		f32(t.y * TILE_SIZE) + f32(TILE_SIZE) * 0.5,
	}
}

entity_set_move_target :: proc(
	ew: ^Entity_World,
	e: Entity,
	tm: ^Tilemap,
	target: Tile_Coord,
) -> bool {
	i := entity_index(e)
	if i < 0 || !ew.active[i] {
		return false
	}

	start := ew.position[i]
	if !pathfind_astar(tm, start, target, &ew.path[i]) {
		return false
	}
	ew.path_index[i] = 1
	if ew.path[i].count <= 1 {
		ew.move_state[i] = .Idle
	} else {
		ew.move_state[i] = .Moving
		ew.move_target[i] = target
	}

	return true
}

entity_update_movement :: proc(ew: ^Entity_World, dt: f32) {
	speed := f32(TILE_SIZE) * MOVE_SPEED

	for i in 0 ..< MAX_ENTITIES {
		if !ew.active[i] || ew.move_state[i] != .Moving {
			continue
		}

		pos := ew.position[i]
		target := ew.move_target[i]
		if pos == target {
			ew.move_state[i] = .Idle
			continue
		}

		p := &ew.path[i]

		if ew.path_index[i] >= p.count {
			ew.move_state[i] = .Idle
			continue
		}

		next := p.tiles[ew.path_index[i]]

		goal := tile_center_world(next)
		vp := ew.visual_position[i]

		dx := goal.x - vp.x
		dy := goal.y - vp.y
		dist := math.sqrt(dx * dx + dy * dy)

		if dist < 1.0 {
			ew.position[i] = next
			ew.visual_position[i] = goal
			ew.path_index[i] += 1

			if ew.path_index[i] >= p.count {
				ew.move_state[i] = .Idle
			}
		} else {
			step := speed * dt
			if step >= dist {
				ew.visual_position[i] = goal
				ew.position[i] = next
				ew.path_index[i] += 1

				if ew.path_index[i] >= p.count {
					ew.move_state[i] = .Idle
				}

			} else {
				ew.visual_position[i].x += dx / dist * step
				ew.visual_position[i].y += dy / dist * step
			}
		}
	}
}

