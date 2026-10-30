extends SceneTree
## godot --headless --path game --script tests/test_grid.gd

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _init() -> void:
	var g := Grid.new(["GGGG", "GFMW", "GGGG"])
	var r := g.reachable(Vector2i(0, 0), 3)
	check(r[Vector2i(0, 0)] == 0, "Start kostet 0")
	check(r[Vector2i(3, 0)] == 3, "Gras-Weg: 3 Kosten")
	check(r[Vector2i(1, 1)] == 3, "Wald kostet 2 (1 Gras + 2 Wald)")
	check(not r.has(Vector2i(2, 1)), "Berg (Kosten 3) nach Wald ausserhalb Reichweite")
	check(not r.has(Vector2i(3, 1)), "Wasser nicht betretbar")
	var fl := g.reachable(Vector2i(0, 0), 4, true)
	check(fl.has(Vector2i(3, 1)), "Fliegende ueberqueren Wasser")
	var blocked := g.reachable(Vector2i(0, 0), 3, false, {Vector2i(1, 0): true})
	check(blocked.get(Vector2i(2, 0), 99) > 3 or not blocked.has(Vector2i(2, 0)), "Feind blockiert Weg")
	var path := g.path_to(Vector2i(0, 0), Vector2i(3, 0), r)
	check(path.size() == 4 and path[0] == Vector2i(0, 0), "Pfadlaenge 4")
	check(Grid.dist(Vector2i(0, 0), Vector2i(2, 3)) == 5, "Manhattan-Distanz")
	# Gelaende: Mausauswahl trifft die Kachel, auch auf dem Berg und am See
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_ch1.json"))
	var tv := TerrainView.new()
	tv.setup(Grid.new(map["rows"]))
	for tile in [Vector2i(3, 4), Vector2i(8, 1), Vector2i(5, 4), Vector2i(1, 8)]:
		var top := Vector3(tile.x, 6.0, tile.y + 5.0)
		var dir := (Vector3(tile.x, tv.tile_height(tile), tile.y) - top).normalized()
		check(tv.pick(top, dir) == tile, "pick trifft Kachel %s" % tile)
	check(tv.tile_height(Vector2i(8, 1)) > tv.tile_height(Vector2i(1, 8)) + 0.4, "Berg liegt hoeher als Wiese")
	check(tv.tile_height(Vector2i(5, 4)) <= TerrainView.WATER_LEVEL + 0.001, "Seekachel: Figurhoehe = Wasseroberflaeche")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
