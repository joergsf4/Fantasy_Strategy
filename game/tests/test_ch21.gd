extends SceneTree

class IntroProbe extends "res://scripts/main.gd":
	var parts: Array = []
	var counts: Array = []

	func _ready() -> void:
		pass

	func _dialogue(lines: Array, _layer_no := 2) -> void:
		parts.append(lines)
		counts.append(stage.battle.units.size())
		await get_tree().process_frame


class FastStage extends Stage:
	func start_battle() -> void:
		set_mode("battle")
		_finish.call_deferred()

	func _finish() -> void:
		battle.finished.emit(true)


class FlowProbe extends "res://scripts/main.gd":
	var events: Array = []
	var travel_party: Array = []

	func _ready() -> void:
		pass

	func _squad_select(m: Dictionary) -> void:
		events.append("select")
		party.set_squad_member(m, 2, "samurai")

	func _prepare_test_chapter(index: int) -> void:
		super._prepare_test_chapter(index)
		party.talents["samurai"] = Talents.default_allocation(Party.points_for(party.earned))
		stage.queue_free()
		stage = FastStage.new()
		stage.setup(map, units)
		stage.party = party
		add_child(stage)

	func _mission_twenty_one_intro(story_c: Dictionary, m: Dictionary) -> void:
		events.append("scene")
		await super._mission_twenty_one_intro(story_c, m)

	func _dialogue(_lines: Array, _layer_no := 2) -> void:
		events.append("dialogue")

	func _camp(_m: Dictionary) -> void:
		events.append("camp")

	func _play_interlude(data: Dictionary) -> void:
		events.append("travel")
		travel_party = data["party"].duplicate()

	func _reward(_res: Dictionary, _fade := true) -> void:
		pass

	func _talent_screen(_ids: Array) -> void:
		pass

	func _cover_in(_t := 0.4) -> void:
		pass

	func _cover_out(_t := 0.5) -> void:
		pass

	func _play_music(_path: String, _fade := 0.0) -> void:
		pass

	func _fade_music(_seconds := 2.5) -> void:
		pass

	func _toast(_text: String) -> void:
		pass


var fails := 0


func check(cond: bool, message: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", message)


func _initialize() -> void:
	Engine.time_scale = 8.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch21")
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story_ch21.json"))
	var p := Party.for_chapter(defs, 21)
	check(m["biome"] == "vulkan" and m["players"].size() == 4 and m["guests"].size() == 1, "Vulkanmission mit vier Gruppenmitgliedern und einem Gast")
	check(m["guests"][0]["id"] == "xiulan" and not defs["xiulan"].get("hero", false), "Xiùlán bleibt eine Gastfigur")
	var squad := p.squad_for(m)
	check(squad.size() == 4 and squad.has("maedchen_baer") and squad.has("ninjas"), "Mira und Kage-Schwestern sind gesetzt")
	check(not p.set_squad_member(m, squad.find("ninjas"), "wendy"), "Kage-Schwestern sind nicht austauschbar")
	check(p.set_squad_member(m, 2, "samurai") and p.squad_for(m)[2] == "samurai", "Freier Gruppenplatz kann gewechselt werden")
	var voiced := Mission.voiced(story["after_flee"], p.squad_for(m))
	check(voiced.any(func(l: Dictionary) -> bool: return l["speaker"] == "samurai"), "Dialogvariante der Auswahl wird verwendet")
	var prior := Party.new_game()
	prior.squads["ch20"] = ["maedchen_baer", "ninjas", "wendy", "samurai", "robo", "ritter"]
	var inherited := prior.squad_for(m)
	check(inherited.size() == 4 and inherited.has("wendy") and inherited.has("samurai"), "Verkleinerte Gruppe uebernimmt die fruehere Auswahl")
	check(not Party.roster(defs, 21, true, []).has("xiulan"), "Gast ist nicht dauerhaft waehlbar")

	var main := IntroProbe.new()
	root.add_child(main)
	main.units = defs
	main.party = p
	main.stage = Stage.new()
	main.stage.setup(m, defs)
	main.stage.party = p
	main.add_child(main.stage)
	await process_frame
	var b := main.stage.battle
	check(m.get("curated_volcano", false) and b.terrain.get_node_or_null("Inst_rock0") == null and b.terrain.get_node_or_null("Inst_rock1") == null, "Keine zufaellig verteilten Steine auf der gestalteten Karte")
	var ground := b.terrain.get_node("Ground") as MeshInstance3D
	check(is_equal_approx(float((ground.material_override as ShaderMaterial).get_shader_parameter("lava_flow")), 1.0), "Erkalteter Lavastrom auf der Missionskarte aktiviert")
	var reference_grid := Grid.new(m["rows"])
	var positions := {}
	for kind in ["players", "guests", "enemies", "chests"]:
		for entry: Dictionary in m.get(kind, []):
			positions[Vector2i(entry["pos"][0], entry["pos"][1])] = true
	var flank_counts := [0, 0]
	for decor: Dictionary in m["decor"]:
		var pos := Vector2i(decor["pos"][0], decor["pos"][1])
		check(not positions.has(pos), "Dekoration verdeckt keine Startposition oder Truhe")
		check(pos.x <= 2 or pos.x >= 10, "Dekoration bleibt an den Flanken")
		if pos.x <= 2:
			flank_counts[0] += 1
		else:
			flank_counts[1] += 1
	check(flank_counts[0] >= 3 and flank_counts[1] >= 3, "Beide Flanken sind bewusst gestaltet")
	check(m["decor"].filter(func(d: Dictionary) -> bool: return d["sprite"] == "fx_vulkantotbaum").size() == 1, "Markanter Vulkanbaum steht fuer sich allein")
	check((m.get("curated_trees", []) as Array).is_empty(), "Keine eingefaerbten Kiefern oder Laubbaeume mehr im Oedland")
	var sprites := {}
	for decor: Dictionary in m["decor"]:
		sprites[decor["sprite"]] = true
		check(ResourceLoader.exists("res://assets/fx/%s.png" % decor["sprite"]), "Deko-Sprite vorhanden: " + str(decor["sprite"]))
		check(not str(decor["sprite"]).begins_with("fx_fels"), "Keine grauen Rundfelsen mehr")
	for want in ["fx_vulkanstumpf", "fx_basaltsaeulen", "fx_obsidian", "fx_schwefel", "fx_fumarole"]:
		check(sprites.has(want), "Vulkan-Requisite auf der Karte: " + want)
	check(m["decor"].filter(func(d: Dictionary) -> bool: return d.get("effect", "") == "smoke").size() >= 2, "Zwei rauchende Fumarolen")
	for y in b.grid.height:
		for x in b.grid.width:
			var pos := Vector2i(x, y)
			check(b.grid.cost(pos) == reference_grid.cost(pos), "Dekoration und Lavastrom aendern keine Bewegungskosten")
	check(m["weather"].has("ash") and m["weather"].has("embers"), "Asche und Glut nutzen die vorhandenen Wettereffekte")
	check(b.units.size() == 11 and b._find("xiulan").get("team") == "p", "Gast und Gegner auf dem Spielfeld")
	check(b._find("xiulan")["hp"] == 78 and b._find("xiulan")["atk"] == 15, "Gast hat missionsgerechte Werte")
	check(b._find("xiulan")["abilities"].has("gebiss") and b._ab_targets(b._find("xiulan"), "gebiss", b._find("xiulan")["pos"]).size() > 0, "Gast kann ihre Gebiss-Faehigkeit gegen Gegner einsetzen")
	check(b._find("oskar").is_empty(), "Oskar ist kein regulärer Gegner")
	check(not b.goal_met(), "Ziel ist zu Beginn nicht erfuellt")
	await main._mission_twenty_one_intro(story, m)
	check(main.parts.size() == 3 and main.counts[0] == 12 and main.counts[2] == 11, "Gespraech, Angriff, Flucht und Eingreifen in Reihenfolge")
	var xl: Dictionary = b._find("xiulan")
	check(xl["pos"] == Vector2i(5, 4) and (xl["node"] as Node3D).position.distance_to(b.to_world(Vector2i(5, 4))) < 0.01, "Xiùlán steht nach der Pruegelwolke wieder auf ihrem Feld")
	check((xl["sprite"] as Sprite3D).visible and (xl["ring"] as Node3D).visible and (xl["bar"] as Node3D).visible, "Xiùlán ist danach normal sichtbar (Bild, Ring, Lebensbalken)")
	check((story["after_beating"] as Array).size() == 1 and story["after_beating"][0]["speaker"] == "xiulan", "Nach dem Flug spricht nur noch Xiùlán (Oskar ist weg)")
	check(main.find_children("*", "CanvasLayer", false, false).all(func(c: Node) -> bool: return c.get_child_count() == 0 or c.is_queued_for_deletion() or c.get_children().all(func(x: Node) -> bool: return not (x is Label and (x as Label).text in ["BAM!", "POW!", "KLONK!", "ZACK!", "WUMMS!", "AUA!"]))), "Lautwoerter sind wieder weg")
	check(b._find("oskar").is_empty() and not b.fled.has("oskar") and b.all_units.size() == 11, "Oskar hinterlaesst keine Kampfeinheit oder Statistik")
	check(b.turn == 1 and b._find("xiulan")["hp"] == 78, "Inszenierung verbraucht weder Runde noch Leben")
	var guest := b._find("xiulan")
	var target: Dictionary = b._ab_targets(guest, "gebiss", guest["pos"])[0]
	target["hp"] = 1000
	target["maxhp"] = 1000
	await b._run_ability(guest, "gebiss", target)
	check(target["hp"] < 1000 and guest["cd"].has("gebiss"), "Xiùlán setzt Gebiss im echten Kampf mit Schaden und Abklingzeit ein")
	var maja := b._find("maja")
	b.units.erase(maja)
	await b._down(maja)
	check(b.fled.has("maja"), "Besiegte Maja flieht mit der normalen Kampflogik")
	check(not b.goal_met(), "Majas Flucht beendet den Kampf nicht, solange Soldaten da sind")
	for unit: Dictionary in b.units.duplicate():
		if unit["team"] == "e":
			b.units.erase(unit)
	check(b.goal_met(), "Sieg nach Maja und allen Soldaten")
	main.stage.new_battle()
	b = main.stage.battle
	for unit: Dictionary in b.units.duplicate():
		if unit["team"] == "e" and unit["id"] != "maja":
			b.units.erase(unit)
	check(not b.goal_met(), "Maja muss auch nach den Soldaten besiegt werden")
	check(not p.recruited.has("xiulan"), "Xiùlán wird nicht rekrutiert")
	main.queue_free()
	await process_frame

	var flow := FlowProbe.new()
	root.add_child(flow)
	flow.units = defs
	flow.party = Party.for_chapter(defs, 20)
	flow.stage = FastStage.new()
	flow.stage.setup(Mission.load_mission("ch20"), defs)
	flow.stage.party = flow.party
	flow.add_child(flow.stage)
	await process_frame
	await flow._chapter("ch20", true, "ch21")
	check(flow.events.find("camp") >= 0 and flow.events.find("travel") > flow.events.find("camp"), "Vulkanreise folgt auch mit Kapitel 21 auf das Lager")
	check(flow.travel_party == flow.party.squad_for(Mission.load_mission("ch20")), "Vulkanreise zeigt die Gruppe aus Kapitel 20")
	check(flow.party.pending_interlude.is_empty(), "Abgespielte Reise wird aus dem Spielstand entfernt")
	var saved := flow.party.to_dict()
	saved["pending_interlude"] = {"scene": "volcano", "party": flow.travel_party.duplicate()}
	var pending_save := Party.from_dict(saved)
	var path := "user://test_ch21_%d.json" % OS.get_process_id()
	pending_save.save(path)
	flow.party = Party.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	flow.party.test_run = true
	flow.stage.party = flow.party
	flow.events.clear()
	await flow._resume_pick(true)
	check(flow.events == ["camp", "travel"] and flow.party.pending_interlude.is_empty(), "Nach Laden einer noch ausstehenden Reise folgt diese einmal auf das Lager")
	flow.events.clear()
	await flow._resume_pick(true)
	check(flow.events == ["camp"], "Bereits gesehene Reise wiederholt sich beim Laden nicht")
	flow.events.clear()
	await flow._chapter("ch21", false)
	check(flow.events.find("select") >= 0 and flow.events.find("scene") > flow.events.find("select"), "Gruppenwahl erfolgt vor der Inszenierung")
	check(flow.stage.battle._find("samurai").get("team") == "p", "Ausgewaehlter Held steht in der Szene und im Kampf")
	check(not flow.party.recruited.has("xiulan"), "Gast bleibt auch nach dem Sieg nicht rekrutiert")
	flow.events.clear()
	await flow._chapter("ch21", true)
	check(not flow.events.has("scene") and flow.stage.battle._find("oskar").is_empty(), "Direktstart ueberspringt die Szene und behaelt eine gueltige Kampfaufstellung")
	flow.queue_free()
	await process_frame

	var direct := FlowProbe.new()
	root.add_child(direct)
	direct.units = defs
	direct.map = Mission.load_mission("ch1")
	OS.set_environment("START_CH", "ch21")
	OS.set_environment("START_SKIP", "0")
	await direct._run()
	check(direct.events.find("select") >= 0 and direct.events.find("travel") > direct.events.find("select") and direct.events.find("scene") > direct.events.find("travel"), "Cheatstart mit Einleitung zeigt die Reise nach Auswahl vor der Szene")
	check(direct.travel_party.has("samurai") and direct.travel_party.size() == 4, "Reise beim Cheatstart zeigt die tatsaechlich ausgewaehlte Gruppe")
	direct.queue_free()
	await process_frame
	var skip_direct := FlowProbe.new()
	root.add_child(skip_direct)
	skip_direct.units = defs
	skip_direct.map = Mission.load_mission("ch1")
	OS.set_environment("START_SKIP", "1")
	await skip_direct._run()
	check(not skip_direct.events.has("travel") and not skip_direct.events.has("scene"), "Cheat-Direktstart ohne Einleitung ueberspringt auch die Reise")
	OS.unset_environment("START_CH")
	OS.unset_environment("START_SKIP")
	skip_direct.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	print("ch21: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
