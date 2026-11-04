extends SceneTree
## Testlabor: Geheimnis waehlen setzt die beiden Helden, die Arena bekommt sie als Kommandoliste.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var heroes: Array = []
	for id: String in defs:
		if defs[id].get("hero", false):
			heroes.append({"id": id, "name": defs[id]["name"]})
	var secs: Array = []
	for s: Dictionary in Secrets.all():
		var t: Dictionary = s["trigger"]
		secs.append({"id": s["id"], "name": s["name"], "heroes": [t["by"], str(t.get("target", t.get("via", t.get("near", t.get("owner", "")))))]})
	check(secs.size() >= 8, "alle aktiven Geheimnisse sind im Labor waehlbar: %d" % secs.size())
	var lab := TestLab.new()
	lab.setup(heroes, [{"id": "soldat_infanterie", "name": "3 Büttel"}], secs)
	root.add_child(lab)
	await process_frame
	var idx := -1
	for i in secs.size():
		if secs[i]["id"] == "turbo_treibstoff":
			idx = i
	lab._pick_secret(idx + 1)
	check(heroes[lab._sh[0].selected]["id"] == "quacksalber" and heroes[lab._sh[1].selected]["id"] == "panzer" and lab._sh[2].selected == 0, "Geheimnis setzt Dr. Humbug und Robina")
	var got: Array = []
	lab.run.connect(func(kind: String, hero: String, _foe: String, _m: bool) -> void: got.append([kind, hero]))
	for b: Button in lab.find_children("*", "Button", true, false):
		if b.text.begins_with("Geheimnis-Arena"):
			b.pressed.emit()
	check(got == [["geheimnis", "quacksalber,panzer"]], "Arena bekommt beide Helden: %s" % [got])
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
