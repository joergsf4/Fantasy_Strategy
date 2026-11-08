extends SceneTree
## godot --headless --path game --script tests/test_flanke.gd
## Blickrichtung sichtbar beim Ziehen: Beim Auswaehlen eines Helden faerben sich Bewegungsfelder, von denen aus er einen Gegner
## im Ruecken (+30 %) oder an der Flanke (+15 %) treffen wuerde.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var b := Battle.new()
	b.setup(Mission.load_mission("ch1"), defs)
	root.add_child(b)
	await process_frame
	var hero: Dictionary = b.unit_at(Vector2i(2, 8))
	var foe: Dictionary = b.unit_at(Vector2i(8, 5))
	foe["pos"] = Vector2i(4, 6)
	b._face_step(foe, Vector2i.UP)          # blickt nach Norden: Ruecken ist Sueden
	check(b._side_from(hero, Vector2i(4, 7)) == "back", "Feld hinter dem Gegner: Ruecken")
	check(b._side_from(hero, Vector2i(3, 6)) == "flank", "Feld neben dem Gegner: Flanke")
	check(b._side_from(hero, Vector2i(4, 5)) == "", "Feld vor dem Gegner: kein Bonus")
	b._select(hero)
	check(b._pos_hint, "Hinweistext erklaert die Farben")
	b._face_step(foe, Vector2i.DOWN)        # jetzt blickt er nach Sueden: dasselbe Feld ist vorne
	check(b._side_from(hero, Vector2i(4, 7)) == "", "nach Drehung ist das Feld vorne")
	print("flanke: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
