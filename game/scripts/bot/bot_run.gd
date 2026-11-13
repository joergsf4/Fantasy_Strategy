extends SceneTree
## Massenlauf des Spieltest-Bots fuer tools/spielbarkeit.py:
##   godot --headless --path game --script scripts/bot/bot_run.gd -- list=<missionen.json>
##   godot --headless --path game --script scripts/bot/bot_run.gd -- job=<job.json> out=<ergebnis.jsonl>
## Job: {"jobs": [{id, mission, variant: {squad, gear, talents, inventory, nemesis, seed}, style: {caution}, banned: {Held: [ids]}}]}
## Ergebnis: eine JSON-Zeile je Kampf (sofort geschrieben, ein Absturz kostet nur einen Kampf).


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	Engine.time_scale = 40.0
	Sfx.muted = true
	var defs := BotSetup.defs()
	if args.has("list"):
		_list(defs, args["list"])
		quit(0)
		return
	var job: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args["job"]))
	var f := FileAccess.open(args["out"], FileAccess.READ_WRITE if FileAccess.file_exists(args["out"]) else FileAccess.WRITE)
	f.seek_end()
	for j: Dictionary in job["jobs"]:
		var b := await BotSetup.build(root, defs, j["mission"], j.get("variant", {}))
		var bot := PlayBot.new(b, {"style": j.get("style", {"caution": 1.0}), "banned": j.get("banned", {}), "time_limit": float(j.get("time_limit", 300.0))})
		var res := await bot.play()
		res["id"] = j["id"]
		res["mission"] = j["mission"]
		res["secrets"] = b.secrets_done.duplicate() if "secrets_done" in b else []
		b.queue_free()
		await process_frame
		f.store_line(JSON.stringify(res))
		f.flush()
	f.close()
	quit(0)


## Metadaten je Kampfmission: Kartengruppe, feste Plaetze, waehlbare Helden, erwartete Punkte und Ausruestungsstufe,
## Faehigkeiten je Held (inkl. Missions-Faehigkeiten "grants").
func _list(defs: Dictionary, out_path: String) -> void:
	var out := {}
	var order := 0
	for cid: String in BotSetup.battle_missions():
		order += 1
		var prep := BotSetup.prepare(defs, cid)
		var party: Party = prep["party"]
		var m: Dictionary = prep["mission"]
		var map_ids: Array = (Mission.load_mission(cid)["players"] as Array).map(func(e: Dictionary) -> String: return e["id"])
		var fixed: Array = []
		if m.get("fixed_squad", false):
			fixed = map_ids.duplicate()
		else:
			var said := Mission.dialogue_ids(cid)
			fixed = map_ids.filter(func(id: String) -> bool: return said.has(id))
		var n := BotSetup.chapter_no(cid)
		var roster: Array = Party.roster(defs, n, true, party.recruited) if not m.get("fixed_squad", false) else map_ids.duplicate()
		var abil := {}
		for id: String in prep["squad"]:
			var ab: Array = (defs.get(id, {}).get("abilities", []) as Array).duplicate()
			ab.append_array((m.get("grants", {}) as Dictionary).get(id, []))
			abil[id] = ab
		var pr: Dictionary = (Progression.data()["missions"] as Dictionary).get(cid, {})
		out[cid] = {"title": m.get("title", cid), "squad": prep["squad"], "fixed": fixed, "roster": roster, "abilities": abil,
			"fixed_squad": m.get("fixed_squad", false), "points": Party.points_for(party.earned), "gear_tier": pr.get("gear_tier", 1.0),
			"nemesis": party.nemesis, "order": order}
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
