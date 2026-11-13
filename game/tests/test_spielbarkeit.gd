extends SceneTree
## godot --headless --path game --script tests/test_spielbarkeit.gd   (SPIEL_NUR=ch5,ch8 fuer einzelne Missionen)
## Spielbarkeit: Ein Bot (scripts/bot/) spielt jede Kampfmission und die Rueckblende mit der Standardgruppe, der erwarteten
## Ausruestung und den erwarteten Talentpunkten auf "Normal". Verliert er auch mit vorsichtigem Stil, schlaegt der Test fehl.
## Ein Bot-Sieg beweist, dass die Mission schaffbar ist; eine Niederlage beweist nicht das Gegenteil (der Bot ist schwaecher als ein Mensch).

var fails := 0


func _initialize() -> void:
	Engine.time_scale = float(OS.get_environment("SPIEL_TEMPO")) if OS.get_environment("SPIEL_TEMPO") != "" else 40.0
	Sfx.muted = true
	var defs := BotSetup.defs()
	var only := OS.get_environment("SPIEL_NUR")
	var t_all := Time.get_ticks_msec()
	for cid: String in BotSetup.battle_missions():
		if only != "" and not only.split(",").has(cid):
			continue
		var res := await _play(defs, cid, {"caution": 1.0})
		var line := _line(cid, res)
		if not res["won"]:
			var res2 := await _play(defs, cid, {"caution": 1.6})
			line += "  | vorsichtig: " + _line(cid, res2)
			if not res2["won"]:
				fails += 1
				print("FAIL: ", line)
				for a: String in res["last_actions"]:
					print("    ", a)
				continue
		print(line)
	print("Gesamtzeit %.0f s" % (float(Time.get_ticks_msec() - t_all) / 1000.0))
	print("spielbarkeit: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)


func _play(defs: Dictionary, cid: String, style: Dictionary) -> Dictionary:
	var b := await BotSetup.build(root, defs, cid)
	var bot := PlayBot.new(b, {"style": style})
	var res := await bot.play()
	b.queue_free()
	await process_frame
	return res


func _line(cid: String, r: Dictionary) -> String:
	var s := "%s: %s in %d Runden, %d übrig, %.0f s" % [cid, r["reason"], r["turns"], (r["survivors"] as Array).size(), r["wall_s"]]
	if not (r["mismatches"] as Array).is_empty():
		s += ", Abweichungen: %d (%s)" % [(r["mismatches"] as Array).size(), r["mismatches"][0]]
	return s
