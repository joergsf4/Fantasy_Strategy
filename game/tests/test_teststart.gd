extends SceneTree

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var initial := Party.new_game()
	var initial_counts := {}
	var initial_value := 0
	for pieces: Array in initial.equipment.values():
		for id: String in pieces:
			initial_counts[id] = int(initial_counts.get(id, 0)) + 1
			initial_value += int(Items.equipment()[id]["price"])
	var budget := 0
	for chapter in range(1, 22):
		var p := Party.for_chapter(defs, chapter)
		var m := Mission.load_mission("ch%d" % chapter)
		check(p.test_run and p.chapter == chapter and p.earned == Progression.missions_done_before(chapter), "Kapitel %d: eigener Teststand und Fortschritt" % chapter)
		for id: String in defs:
			if defs[id].get("hero", false):
				check(Talents.spent(p.talents[id]) == Party.points_for(p.earned), "Kapitel %d: Talentpunkte fuer %s verteilt" % [chapter, id])
		var counts := {}
		var value := 0
		for hero: String in p.equipment:
			var slots := {}
			for id: String in p.equipment[hero]:
				var item: Dictionary = Items.equipment()[id]
				check(not slots.has(item["slot"]) and Items.can_equip({"dmg_type": defs[hero].get("dmg_type", "body"), "range": int(defs[hero].get("range", 1))}, id), "Kapitel %d: tragbare Ausruestung ohne doppelte Plaetze" % chapter)
				slots[item["slot"]] = true
				counts[id] = int(counts.get(id, 0)) + 1
				value += int(item["price"])
		for id: String in p.pool:
			counts[id] = int(counts.get(id, 0)) + 1
			value += int(Items.equipment()[id]["price"])
		check(p.gold >= 0 and p.gold + value - initial_value <= budget, "Kapitel %d: Ausgaben und Restgold durch Beute gedeckt" % chapter)
		var limits := initial_counts.duplicate()
		for shop_chapter in range(2, chapter + 1):
			var prev := Mission.load_mission("ch%d" % (shop_chapter - 1))
			var next := Mission.load_mission("ch%d" % shop_chapter)
			if not ((not prev.get("stub", false) and not next.get("stub", false)) or (prev.get("stub", false) and prev.get("camp_after", false))):
				continue
			var merchant: String = Party.merchant_at(shop_chapter).get("id", "")
			for item: Dictionary in Party.shop_data()["stock"]:
				if Items.equipment().has(item["id"]) and item.get("for", "sack") == merchant and int(item.get("from", 1)) <= shop_chapter and int(item.get("until", 9999)) >= shop_chapter:
					limits[item["id"]] = int(limits.get(item["id"], 0)) + int(item["n"])
		for id: String in counts:
			check(int(counts[id]) <= int(limits.get(id, 0)), "Kapitel %d: %s nur in verfuegbarer Anzahl" % [chapter, id])
		if not m.get("stub", false):
			budget += int((m.get("rewards", {}) as Dictionary).get("gold", 0))
			var optional := 0
			for chest: Dictionary in m.get("chests", []):
				optional += int((chest.get("reward", {}) as Dictionary).get("gold", 0))
			for objective: Dictionary in m.get("objectives", []):
				optional += int((objective.get("reward", {}) as Dictionary).get("gold", 0))
			budget += optional / 2
	var early := Party.for_chapter(defs, 1)
	check(early.gold == 0 and early.inventory == initial.inventory and early.equipment == initial.equipment, "Kapitel 1 behaelt die regulaere Startausstattung")
	var late := Party.for_chapter(defs, 20)
	check(late.points("robo") == 0 and late.worn_in("robo", "talisman") == "fernrohr", "Spaete Gruppe ist ausgebildet und Robo bekommt Reichweite")
	var main = load("res://scripts/main.gd").new()
	main.units = defs
	main.stage = Stage.new()
	var original := Party.new_game()
	original.gold = 1234
	main.party = original
	main.stage.party = original
	main._prepare_test_chapter(19)
	check(main.party != original and original.gold == 1234 and main.party.chapter == 20 and main.stage.party == main.party, "Kapitelwahl setzt neuen Teststand auf der Buehne ein")
	var mission := Mission.load_mission("ch20")
	var squad: Array = main.party.squad_for(mission)
	var old_gear: Array = (main.party.equipment.get(squad[2], []) as Array).duplicate()
	check(main.party.set_squad_member(mission, 2, "samurai"), "Testgruppe kann gewechselt werden")
	main._mission_with_squad("ch20")
	check(not main.party.equipment.get("samurai", []).is_empty() and not main.party.equipment.has(squad[2]) and not old_gear.is_empty(), "Ersatzheld bekommt verfuegbare Ausruestung")
	var save_path := "user://test_teststart_%d.json" % OS.get_process_id()
	original.save(save_path)
	main.party.save(save_path)
	check(Party.load_from(save_path).gold == 1234, "Teststand ueberschreibt keinen Spielstand")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	main.stage.free()
	main.free()
	print("teststart: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
