extends SceneTree
## godot --headless --path game --script tests/test_camp.gd
## Haendler, Brauen und Ausruestung im Party-Zustand.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func price(id: String) -> int:
	for w: Dictionary in Party.shop_data()["chapter1"]:
		if w["id"] == id:
			return int(w["price"])
	return 0


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var p := Party.new_game()
	var ht_price := price("heiltrank")
	p.gold = price("kettenhemd") - 1
	# Kaufen
	check(p.can_buy("heiltrank") and not p.can_buy("kettenhemd"), "Knapp unter dem Kettenhemd-Preis: Heiltrank ja, Kettenhemd nein")
	p.gold = ht_price * 3 + 5
	check(p.buy("heiltrank") and p.gold == ht_price * 2 + 5 and p.inventory["heiltrank"] == 3, "Heiltrank gekauft: Preis abgezogen, 3 im Rucksack")
	check(p.buy("heiltrank") and p.buy("heiltrank") and p.gold == 5, "3 Heiltraenke Vorrat")
	check(not p.buy("heiltrank") and p.gold == 5, "Vierter Heiltrank: ausverkauft, kein Gold abgezogen")
	p.gold = 500
	check(p.buy("eisenschwert") and p.pool.has("eisenschwert") and p.gold == 500 - price("eisenschwert"), "Ausruestung kommt ins Lager")
	check(not p.buy("eisenschwert"), "Eisenschwert nur einmal im Vorrat")
	check(not p.buy("gibt_es_nicht") and p.gold == 500 - price("eisenschwert"), "Unbekannte Ware nicht kaufbar")
	var low := Party.new_game()
	low.gold = ht_price - 1
	check(not low.buy("heiltrank") and low.gold == ht_price - 1, "Zu wenig Gold: nichts passiert")
	# Vorrat setzt sich im naechsten Kapitel zurueck
	p.absorb({"inventory": p.inventory, "materials": {}, "gold": 0, "equipment": []})
	check(p.chapter == 2 and p.bought.is_empty(), "Neues Kapitel: Vorrat zurueckgesetzt")
	# Brauen
	var q := Party.new_game()
	q.materials = {"kraut": 3, "hopfen": 1, "kristall": 2}
	check(q.can_brew("heiltrank") and q.can_brew("gegengift") and q.can_brew("aether") and not q.can_brew("bier"), "Brauen: Heiltrank, Gegengift, Aether ja; Bier nein (nur 1 Hopfen)")
	var ht: int = q.inventory["heiltrank"]
	check(q.brew("heiltrank") and q.materials["kraut"] == 1 and q.inventory["heiltrank"] == ht + 1, "Heiltrank gebraut: -2 Kraut, +1 Trank")
	check(not q.brew("heiltrank") and q.materials["kraut"] == 1, "Zu wenig Kraut: nichts passiert")
	check(q.brew("gegengift") and q.materials["kraut"] == 0, "Gegengift: -1 Kraut")
	check(q.brew("aether") and q.materials["kristall"] == 0, "Aether: -2 Kristall")
	check(not q.brew("unbekannt"), "Unbekanntes Rezept")
	# Ausruestung anlegen
	var r := Party.new_game()
	r.pool = ["schwere_axt", "eisenschwert", "plattenpanzer", "kristallstab", "fernrohr"]
	var br: Dictionary = defs["braumeisterin"]
	check(r.worn_in("braumeisterin", "waffe") == "eisenschwert", "Brunhilde traegt Eisenschwert (Startausstattung)")
	check(r.equip("braumeisterin", "schwere_axt", br), "Axt anlegen")
	check(r.worn_in("braumeisterin", "waffe") == "schwere_axt" and r.pool.has("eisenschwert") and not r.pool.has("schwere_axt"), "Altes Eisenschwert zurueck ins Lager, Axt getragen")
	check(not r.equip("braumeisterin", "kristallstab", br), "Kristallstab: nur Magier")
	check(not r.equip("braumeisterin", "fernrohr", br), "Fernrohr: nur Fernkaempfer")
	check(r.equip("braumeisterin", "plattenpanzer", br) and r.worn_in("braumeisterin", "ruestung") == "plattenpanzer", "Panzer anlegen")
	check(not r.equip("braumeisterin", "nicht_im_lager", br), "Nur Stuecke aus dem Lager")
	r.unequip("braumeisterin", "waffe")
	check(r.worn_in("braumeisterin", "waffe") == "" and r.pool.has("schwere_axt"), "Ablegen: zurueck ins Lager")
	var cl: Dictionary = defs["claude"]
	check(r.equip("claude", "kristallstab", cl), "Claude (Magier) traegt den Kristallstab")
	# Speichern behaelt Vorrat und Ausruestung
	var path := "user://test_camp.json"
	p.save(path)
	var l := Party.load_from(path)
	check(l.chapter == p.chapter and l.pool == p.pool and l.gold == p.gold, "Speichern/Laden: Lager und Gold gleich")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
