package main

Path :: struct {
	tiles: [dynamic]Tile_Coord,
	count: int,
}

max_path_int :: 1_000_000_000

path_clear :: proc(path: ^Path) {
	resize(&path.tiles, 0)
	path.count = 0
}

pathfind_bfs :: proc(tilemap: ^Tilemap, start, goal: Tile_Coord, path: ^Path) -> bool {
	path_clear(path)

	if start == goal {
		resize(&path.tiles, 1)
		path.tiles[0] = start
		path.count = 1
		return true
	}

	w, h := tilemap.width, tilemap.height

	parents: [MAP_HEIGHT][MAP_WIDTH]Tile_Coord
	visited: [MAP_HEIGHT][MAP_WIDTH]bool

	found := false

	for y in 0 ..< h {
		for x in 0 ..< w {
			parents[y][x] = {-1, -1}
		}
	}

	queue: [MAP_WIDTH * MAP_HEIGHT]Tile_Coord
	head, tail: int = 0, 0

	queue[tail] = start; tail += 1
	visited[start.y][start.x] = true
	parents[start.y][start.x] = start

	for head < tail {
		current := queue[head]; head += 1

		if current == goal {
			found = true
			break
		}

		for offset in NEIGHBOR_OFFSET {
			nx := current.x + offset.x
			ny := current.y + offset.y
			if !tile_in_bounds(tilemap, nx, ny) ||
			   visited[ny][nx] ||
			   !tile_walkable(tilemap, nx, ny) {
				continue
			}

			visited[ny][nx] = true
			parents[ny][nx] = current
			queue[tail] = {nx, ny}
			tail += 1
		}
	}

	if !found {
		return false
	}

	return path_reconstruct(&parents, start, goal, path)
}

manhattan :: proc(a, b: Tile_Coord) -> int {
	return abs(a.x - b.x) + abs(a.y - b.y)
}

pathfind_astar :: proc(tm: ^Tilemap, start, goal: Tile_Coord, path: ^Path) -> bool {
	path_clear(path)

	if start == goal {
		resize(&path.tiles, 1)
		path.tiles[0] = start
		path.count = 1
		return true
	}

	if !tile_walkable(tm, goal.x, goal.y) {
		return false
	}

	w, h := tm.width, tm.height

	g_score: [MAP_HEIGHT][MAP_WIDTH]int
	f_score: [MAP_HEIGHT][MAP_WIDTH]int
	parents: [MAP_HEIGHT][MAP_WIDTH]Tile_Coord
	open: [MAP_HEIGHT][MAP_WIDTH]bool
	closed: [MAP_HEIGHT][MAP_WIDTH]bool

	for y in 0 ..< h {
		for x in 0 ..< w {
			g_score[y][x] = max_path_int
			f_score[y][x] = max_path_int
			parents[y][x] = {-1, -1}
		}
	}

	g_score[start.y][start.x] = 0
	f_score[start.y][start.x] = manhattan(start, goal)
	parents[start.y][start.x] = start
	open[start.y][start.x] = true

	open_list: [MAP_WIDTH * MAP_HEIGHT]Tile_Coord
	open_count := 1
	open_list[0] = start

	found := false

	for open_count > 0 {
		best_i := 0
		best_f := max_path_int
		for i in 0 ..< open_count {
			c := open_list[i]
			if f_score[c.y][c.x] < best_f {
				best_f = f_score[c.y][c.x]
				best_i = i
			}
		}

		current := open_list[best_i]
		open_list[best_i] = open_list[open_count - 1]
		open_count -= 1
		open[current.y][current.x] = false
		closed[current.y][current.x] = true

		if current == goal {
			found = true
			break
		}

		for offset in NEIGHBOR_OFFSET {
			nx := current.x + offset.x
			ny := current.y + offset.y
			if !tile_in_bounds(tm, nx, ny) || closed[ny][nx] {
				continue
			}

			step_cost := tile_cost(tm, nx, ny)
			if step_cost >= max_path_int {
				continue
			}

			tentative := g_score[current.y][current.x] + step_cost
			if tentative < g_score[ny][nx] {
				parents[ny][nx] = current
				g_score[ny][nx] = tentative
				f_score[ny][nx] = tentative + manhattan({nx, ny}, goal)

				if !open[ny][nx] {
					open[ny][nx] = true
					open_list[open_count] = {nx, ny}
					open_count += 1
				}
			}
		}
	}
	if !found {
		return false
	}

	return path_reconstruct(&parents, start, goal, path)
}

path_reconstruct :: proc(
	parents: ^[MAP_HEIGHT][MAP_WIDTH]Tile_Coord,
	start, goal: Tile_Coord,
	path: ^Path,
) -> bool {
	rev: [MAX_PATH]Tile_Coord
	rev_count := 0
	cur := goal

	for {
		if rev_count >= MAX_PATH {
			return false
		}

		rev[rev_count] = cur
		rev_count += 1

		if cur == start {
			break
		}

		cur = parents[cur.y][cur.x]
	}

	resize(&path.tiles, rev_count)
	path.count = rev_count

	for i in 0 ..< rev_count {
		path.tiles[i] = rev[rev_count - 1 - i]
	}

	return true
}

path_destroy :: proc(path: ^Path) {
	delete(path.tiles)
	path.tiles = nil
	path.count = 0
}

