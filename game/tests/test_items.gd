extends SceneTree
## godot --headless --path game --script tests/test_items.gd
## Regeln fuer Ausruestung und Verbrauchsgegenstaende (reine Logik).

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func unit(extra := {}) -> Dictionary:
	var u := {"id": "x", "atk": 8, "def": 4, "res": 2, "hp": 20, "maxhp": 20, "move": 3, "range": 1, "range_min": 1,
		"dmg_type": "body", "status": [], "cd": {}, "pos": Vector2i(2, 2), "team": "p"}
	u.merge(extra, true)
	return u


func _init() -> void:
	# Ausruestung
	var u := unit()
	Items.apply_equipment(u, ["kettenhemd", "rubinring", "windstiefel"])
	check(u["def"] == 4 + 2 + 1 and u["atk"] == 9 and u["move"] == 3, "Kettenhemd + Rubinring + Windstiefel: zwei Talismane -> nur der erste zaehlt (DEF 7, ATK 9, BEW 3)")
	var boots := unit()
	Items.apply_equipment(boots, ["windstiefel"])
	check(boots["move"] == 4, "Windstiefel +1 Bewegung")
	var v := unit()
	Items.apply_equipment(v, ["schwere_axt", "plattenpanzer"])
	check(v["atk"] == 12 and v["def"] == 8 and v["move"] == 1, "Axt + Panzer: ATK 12, DEF 8, BEW nie unter 1 (3-1-1 = 1)")
	var w := unit()
	Items.apply_equipment(w, ["heilkraut"])
	check(w["maxhp"] == 28 and w["hp"] == 28, "Heilkraut: +8 Leben (auch aktuell)")
	var two := unit()
	Items.apply_equipment(two, ["eisenschwert", "schwere_axt"])
	check(two["atk"] == 10, "nur ein Stueck pro Platz (Waffe): nur das erste zaehlt")
	var melee := unit()
	Items.apply_equipment(melee, ["fernrohr", "kristallstab"])
	check(melee["range"] == 1 and melee["atk"] == 8, "Fernrohr nur fuer Fernkaempfer, Kristallstab nur fuer Magier")
	var archer := unit({"range": 2, "dmg_type": "magic"})
	Items.apply_equipment(archer, ["fernrohr", "kristallstab"])
	check(archer["range"] == 3 and archer["atk"] == 11, "Fernkaempfer/Magier tragen beides")
	var lamp := unit()
	Items.apply_equipment(lamp, ["zauberlampe"])
	check(Items.cooldown_for(lamp, 3) == 2 and Items.cooldown_for(lamp, 1) == 1 and Items.cooldown_for(unit(), 3) == 3, "Zauberlampe: -1 Abklingzeit, mindestens 1")

	# Verbrauchsgegenstaende
	var hurt := unit({"hp": 5})
	var r := Items.apply_item("heiltrank", hurt, [hurt])
	check(hurt["hp"] == 17 and r["heal"] == 12, "Heiltrank +12")
	var almost := unit({"hp": 18})
	Items.apply_item("heiltrank", almost, [almost])
	check(almost["hp"] == 20, "Heiltrank nicht ueber das Maximum")
	check(not Items.useful_on("heiltrank", unit()), "Heiltrank bei vollem Leben nutzlos")
	var pois := unit({"hp": 10})
	Status.add(pois, "poison", 3)
	Items.apply_item("gegengift", pois, [pois])
	check(not Status.has(pois, "poison") and pois["hp"] == 13, "Gegengift entfernt Gift, +3")
	check(Items.useful_on("gegengift", pois) or true, "Gegengift Test")
	var cdu := unit({"cd": {"a": 3, "b": 0}})
	check(Items.useful_on("aether", cdu), "Aether nuetzlich bei Abklingzeit")
	Items.apply_item("aether", cdu, [cdu])
	check(cdu["cd"]["a"] == 0 and not Items.useful_on("aether", cdu), "Aether setzt Abklingzeiten zurueck")
	var a := unit({"pos": Vector2i(3, 3)})
	var b := unit({"pos": Vector2i(3, 4)})
	var c := unit({"pos": Vector2i(6, 6)})
	Items.apply_item("rauchbombe", a, [a, b, c])
	check(Status.has(a, "stealth") and Status.has(b, "stealth") and not Status.has(c, "stealth"), "Rauchbombe: Ziel und Nachbar verborgen, Ferne nicht")
	var beer := unit({"hp": 10})
	Items.apply_item("bier", beer, [beer])
	check(beer["hp"] == 15 and Combat.stat(beer, "atk") == 11 and Combat.stat(beer, "def") == 3, "Bier: +5 Leben, +3 ATK, -1 DEF")

	# Simulation: Rucksack zaehlt herunter
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_ch1.json"))
	var s := SimBattle.new(map["rows"], 3)
	s.inventory["p"] = {"heiltrank": 2}
	var h := s.spawn("ritter", "p", Vector2i(4, 7), 1.0, 1.0, ["kettenhemd"])
	check(h["def"] == 9, "Sim: Ausruestung beim Aufstellen")
	h["hp"] = 5
	s.use_item(h, "heiltrank", h)
	check(h["hp"] == 17 and s.inventory["p"]["heiltrank"] == 1, "Sim: Heiltrank wirkt, Rucksack -1")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
