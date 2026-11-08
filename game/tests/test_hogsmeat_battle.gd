extends SceneTree

var fails := 0
var dialogues: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func record_dialogue(lines: Array) -> void:
	dialogues.append(lines)


func _initialize() -> void:
	Engine.time_scale = 1.0
	Sfx.muted = true
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch20")
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = record_dialogue
	root.add_child(b)
	await process_frame
	check(m["mood"] == "nacht" and not b.has_node("Rain"), "Hogsmeat bleibt dunkel ohne Regen")
	var fire := b.get_node_or_null("Campfire")
	check(fire != null and fire.get_node_or_null("CampfireLight") is OmniLight3D, "Lagerfeuer besitzt ein echtes 3D-Punktlicht")
	var fire_pos := Vector2i(6, 3)
	check(b.grid.cost(fire_pos) > 0 and b.world.at(fire_pos).is_empty() and b.unit_at(fire_pos).is_empty(), "Lagerfeuer ist reine Dekoration auf einem freien, begehbaren Feld")
	if fire != null and fire.get_node_or_null("CampfireLight") is OmniLight3D:
		var light := fire.get_node("CampfireLight") as OmniLight3D
		var initial_energy := light.light_energy
		var changed := false
		for i in 12:
			await create_timer(0.05).timeout
			changed = changed or not is_equal_approx(light.light_energy, initial_energy)
		check(changed and light.omni_range > 0.0, "Lagerfeuerlicht flackert")
	Engine.time_scale = 15.0
	check(b._count_team("p") == 6 and b._count_team("e") == 6 and b._find("cyborg_wart").is_empty() and not b.goal_met(), "Mission startet ohne Robowart")
	var hero := b._find("maedchen_baer")
	var spear := b._find("hogsmeat_speerwerfer")
	check(not hero.is_empty() and not spear.is_empty(), "Held und Speerwerfer sind aufgebaut")
	check(spear["maxhp"] == int(defs["hogsmeat_speerwerfer"]["hp"]) * 2 and spear["atk"] == int(defs["hogsmeat_speerwerfer"]["atk"]) * 2, "Gegnerfaktoren werden im Kampf angewendet")
	var warriors: Array = b.units.filter(func(u: Dictionary) -> bool: return u["id"] == "hogsmeat_krieger")
	var old_pos: Vector2i = warriors[1]["pos"]
	var cover := b._cover_for(warriors[0], warriors[0]["pos"])
	warriors[1]["pos"] = warriors[0]["pos"] + Vector2i.RIGHT
	check(b._cover_for(warriors[0], warriors[0]["pos"]) == cover + 1, "Benachbarte Krieger bilden einen Schildwall")
	warriors[1]["pos"] = old_pos
	check(b.fx.cfg["_basic"]["hogsmeat_speerwerfer"] == "fx_hogsmeat_speer" and b.fx.tex("fx_hogsmeat_speer") != null, "Speer-Projektil wird geladen")
	var hp: int = hero["hp"]
	await b._strike(spear, hero)
	check(hero["hp"] < hp, "Speerwerfer trifft mit Fernangriff")
	hero["atk"] = 1000
	var enemies: Array = b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "e")
	for enemy: Dictionary in enemies:
		if enemy["id"] != "frischlinge":
			await b._strike(hero, enemy, 1.0, 0.0, false, true)
	check(b._find("cyborg_wart").is_empty() and b._count_team("e") == 1, "Robowart erscheint nicht beim Besiegen anderer Gegner")
	hero["pos"] = Vector2i(7, 2)
	await b._resolve(hero, b._find("frischlinge"))
	var wart := b._find("cyborg_wart")
	check(not wart.is_empty() and wart["pos"] != hero["pos"] and b._count_team("e") == 1 and not b.goal_met() and b.state != Battle.State.OVER, "Nach letztem Gegner erscheint Robowart auf freiem Feld statt vorzeitigem Sieg")
	await b._strike(hero, wart, 1.0, 0.0, false, true)
	check(b.goal_met() and b._count_team("e") == 0, "Siegziel nach allen Gegnern erreicht")
	var completion := {"won": false}
	b.finished.connect(func(won: bool) -> void: completion["won"] = won)
	await b._check_end()
	check(b.state == Battle.State.OVER and completion["won"], "Kampf endet mit Sieg")
	check(b.fled.has("frischlinge") and b.fled.has("cyborg_wart") and dialogues.size() == 3, "Beide benannten Gegner fliehen mit Dialog; Robowart spricht bei seinem Auftritt")
	var result := b.results()
	check(result["fled"].has("frischlinge") and result["fled"].has("cyborg_wart") and int(result["gold"]) >= 400, "Flucht und Missionsbelohnung im Ergebnis")
	var p := Party.new_game()
	p.chapter = 19
	p.squads["ch19"] = ["maedchen_baer", "hund", "samurai", "elisabeth", "robo", "wendy"]
	p.absorb({"inventory": {}, "gold": 0, "equipment": []})
	check(p.chapter == 20 and p.squad_for(m) == p.squads["ch19"] and p.merchant().get("id", "") == "morgrim", "Nach Mission 19 warten Morgrim und die bisherige Gruppe")
	var save_path := "user://test_hogsmeat_%d.json" % OS.get_process_id()
	p.save(save_path)
	var loaded := Party.load_from(save_path)
	check(loaded != null and loaded.chapter == 20 and loaded.squad_for(m) == p.squads["ch19"], "Kapitel 20 und Gruppe aus Spielstand fortsetzen")
	check(loaded.set_squad_member(m, 2, "ritter"), "Gruppe fuer Hogsmeat kann geaendert werden")
	loaded.save(save_path)
	var chosen := Party.load_from(save_path)
	check(chosen != null and chosen.squad_for(m)[2] == "ritter", "Eigene Hogsmeat-Auswahl bleibt nach erneutem Laden erhalten")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	p.absorb(result)
	check(p.chapter == 21 and p.nemesis.has("frischlinge") and p.nemesis.has("cyborg_wart"), "Missionsende uebernimmt Flucht und Fortschritt")
	b.queue_free()
	await process_frame
	var early := Battle.new()
	early.setup(Mission.load_mission("ch20"), defs)
	early.dialogue_runner = record_dialogue
	root.add_child(early)
	await process_frame
	var early_hero := early._find("maedchen_baer")
	early_hero["atk"] = 1000
	await early._strike(early_hero, early._find("frischlinge"), 1.0, 0.0, false, true)
	check(early._count_team("e") == 6 and not early._find("cyborg_wart").is_empty(), "Robowart erscheint auch wenn noch andere Gegner leben")
	early.queue_free()
	await process_frame
	print("hogsmeat_kampf: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
