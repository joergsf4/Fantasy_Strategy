extends SceneTree
## godot --headless --path game --script tests/test_save_migration.gd
## Alte Spielstaende (0.9.1, ohne Feld "order"): ab dem alten Kapitel 17 ruecken Kapitel und gespeicherte Gruppen um eins nach hinten
## (Zwischenspiel nach Mission 16 eingefuegt). Neue Spielstaende (order 1) bleiben unveraendert.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var old := Party.from_dict({"chapter": 18, "squads": {"ch17": ["hund"], "ch18": ["robo"], "ch5": ["wendy"]}})
	check(old.chapter == 19, "altes Kapitel 18 ist jetzt 19 (%d)" % old.chapter)
	check(old.squads.get("ch18", []) == ["hund"] and old.squads.get("ch19", []) == ["robo"] and old.squads.get("ch5", []) == ["wendy"], "Gruppen wandern mit: %s" % [old.squads])
	var early := Party.from_dict({"chapter": 9})
	check(early.chapter == 9, "fruehe Kapitel bleiben")
	var cur := Party.from_dict({"order": Party.ORDER, "chapter": 18, "squads": {"ch18": ["hund"]}})
	check(cur.chapter == 18 and cur.squads.has("ch18"), "neuer Spielstand bleibt unveraendert")
	var p := Party.new_game()
	check(int(p.to_dict()["order"]) == Party.ORDER, "Spielstand speichert die Reihenfolge")
	print("save_migration: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
