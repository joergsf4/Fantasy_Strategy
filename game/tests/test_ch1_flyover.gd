extends SceneTree

class MainProbe extends "res://scripts/main.gd":
	signal release_dialogue
	var flights := 0
	var dialogue_lines: Array = []
	var dialogue_fov := 0.0
	var dialogue_mode := ""
	var dialogue_cover_alpha := -1.0

	func _ready() -> void:
		pass

	func _mission_one_flyover() -> void:
		flights += 1
		await super._mission_one_flyover()

	func _dialogue(lines: Array, _layer_no := 2) -> void:
		dialogue_lines = lines
		dialogue_fov = stage.battle.cam.fov
		dialogue_mode = stage.mode
		for child in get_children():
			if child is CanvasLayer and child.layer == 29 and child.get_child_count() > 0:
				dialogue_cover_alpha = (child.get_child(0) as ColorRect).modulate.a
		await release_dialogue


var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func make_main(defs: Dictionary) -> MainProbe:
	var main := MainProbe.new()
	root.add_child(main)
	main.units = defs
	main.party = Party.new_game()
	main.stage = Stage.new()
	main.stage.setup(Mission.load_mission("ch1"), defs)
	main.stage.party = main.party
	main.add_child(main.stage)
	return main


func _initialize() -> void:
	Engine.time_scale = 8.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var main := make_main(defs)
	await process_frame
	main._chapter("ch1")
	await create_timer(2.0).timeout
	var stage := main.stage
	var battle := stage.battle
	check(main.flights == 1 and stage.mode == "flyover", "Kapitel 1 startet die Kamerafahrt")
	check(main._music != null and main._music.stream.resource_path == main.BATTLE_MUSIC and main._music.playing, "Kampfmusik spielt bereits bei der Kamerafahrt")
	var music := main._music
	var sky := stage._flyover_clouds.get_child(0) as MeshInstance3D
	check((sky.material_override as StandardMaterial3D).albedo_color.b > (sky.material_override as StandardMaterial3D).albedo_color.r, "Hintergrund der Kamerafahrt ist blau")
	check(stage._flyover_clouds.get_child_count() == 4, "Wolken sind fuer die Kamerafahrt vorhanden")
	check(battle._in_stage and not battle._hud_layer.visible and not battle._cursor.visible and not battle.is_processing_unhandled_input(), "Keine Kampfbedienung oder HUD waehrend der Fahrt")
	var enemy_count := 0
	for unit: Dictionary in battle.units:
		if unit["team"] == "e":
			enemy_count += 1
	check(enemy_count >= 6, "Echte gegnerische Truppen sind vorhanden")
	stage.mission_one_flyover_at(0.0)
	var start := battle.cam.position
	var direction := -battle.cam.global_basis.z
	stage.mission_one_flyover_at(0.5)
	var middle := battle.cam.position
	stage.mission_one_flyover_at(1.0)
	var end := battle.cam.position
	check(start.x < middle.x and middle.x < end.x and start.z > middle.z and middle.z > end.z, "Geradlinige Diagonale ohne Richtungswechsel")
	check((middle - start).is_equal_approx((end - middle)) and direction.is_equal_approx(-battle.cam.global_basis.z), "Fahrt behaelt Blickrichtung und gleichmaessigen Weg")
	check(absf(direction.y) < sin(PI / 4.0), "Blickwinkel ist flacher als 45 Grad")
	await create_timer(11.0).timeout
	check(main.dialogue_mode == "dialog" and is_equal_approx(main.dialogue_fov, 34.0), "Nach Schwarzblende startet der unveraenderte Dialog mit Dialogkamera")
	check(main._music == music and stage._flyover_clouds == null, "Musik laeuft weiter; Himmel und Wolken werden fuer den Dialog zurueckgesetzt")
	check(main.dialogue_cover_alpha >= 0.99, "Dialogkamera wird unter vollstaendiger Schwarzblende gesetzt")
	check(not main.dialogue_lines.is_empty() and stage.mode == "dialog", "Einleitungsdialog wird aufgerufen")
	await create_timer(1.0).timeout
	var covers := 0
	for child in main.get_children():
		if child is CanvasLayer and child.layer == 29:
			covers += 1
	check(main._cover == null and covers == 0, "Schwarzblende wird wieder entfernt")
	main.queue_free()
	await process_frame

	var skipped := make_main(defs)
	skipped._chapter("ch1", true)
	await create_timer(0.2).timeout
	check(skipped.flights == 0 and skipped.dialogue_lines.is_empty() and skipped.stage.mode != "flyover", "Uebersprungene Einleitung startet keine Kamerafahrt")
	skipped.queue_free()
	await process_frame

	var later := make_main(defs)
	later._chapter("ch2")
	await create_timer(0.2).timeout
	check(later.flights == 0 and later.dialogue_mode == "dialog" and not later.dialogue_lines.is_empty(), "Andere Kapitel behalten ihren Dialogstart")
	later.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	print("ch1_flyover: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
