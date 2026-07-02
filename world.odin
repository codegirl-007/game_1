package main

World :: struct {
	entities: Entity_World,
}

world_init :: proc() -> World {
	w := World{}
	w.entities = entity_world_init()
	return w
}

world_draw :: proc(w: ^World, camera: ^Camera2D) {
	entity_draw(&w.entities, camera)
}

