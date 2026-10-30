extends SceneTree
## Massenlauf ohne Grafik:
##   godot --headless --path game --script sim/run.gd -- job=<job.json> out=<ergebnis.json>
## Ein Job besteht aus Zellen; jede Zelle beschreibt eine Aufstellung und einen Bereich [from, to) von Wiederholungen.
## Gleiche seed + Index ergeben gleiche Karte und Aufstellung, auch wenn z. B. eine Faehigkeit abgeschaltet ist
## (gepaarter Vergleich). Ausgabe: nur Summen, damit parallele Laeufe addiert werden koennen.
##
## Zelle: {name, from, to, seed, map: "open"|"ch1",
##   party: {fixed:[ids]} | {forced:[ids], pool:[ids], size:n},
##   enemy: {fixed:[ids]} | {mix:{id:count}} | {pool:[ids], count:n | count_range:[a,b]},
##   p_mods: {hp, atk}, e_mods: {hp, atk}, disabled: {id:[abilities]|["*"]}, p_ai: {...}, e_ai: {...}, raw: bool}


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var job: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args["job"]))
	var out := {}
	for cell: Dictionary in job["cells"]:
		out[cell["name"]] = run_cell(cell)
	var f := FileAccess.open(args["out"], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	quit(0)


func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func _party(spec: Dictionary, rng: RandomNumberGenerator) -> Array:
	if spec.has("fixed"):
		return (spec["fixed"] as Array).duplicate()
	var out: Array = (spec.get("forced", []) as Array).duplicate()
	var pool: Array = (spec["pool"] as Array).filter(func(x: String) -> bool: return not out.has(x))
	_shuffle(pool, rng)
	var size := int(spec.get("size", 6))
	if spec.has("size_range"):
		size = rng.randi_range(int(spec["size_range"][0]), int(spec["size_range"][1]))
	out.append_array(pool.slice(0, maxi(0, size - out.size())))
	return out


func _enemies(spec: Dictionary, rng: RandomNumberGenerator) -> Array:
	if spec.has("fixed"):
		return (spec["fixed"] as Array).duplicate()
	var out: Array = []
	if spec.has("mix"):
		for id: String in spec["mix"]:
			for i in int(spec["mix"][id]):
				out.append(id)
		return out
	var pool: Array = spec["pool"]
	var n := int(spec.get("count", 6))
	if spec.has("count_range"):
		n = rng.randi_range(int(spec["count_range"][0]), int(spec["count_range"][1]))
	for i in n:
		out.append(pool[rng.randi() % pool.size()])
	return out


func _units(ids: Array, mods: Dictionary) -> Array:
	var out: Array = []
	for id in ids:
		out.append({"id": id, "hp": float(mods.get("hp", 1.0)), "atk": float(mods.get("atk", 1.0))})
	return out


func run_cell(cell: Dictionary) -> Dictionary:
	SimBattle.reset_defs()
	if cell.has("ab_status_turns"):
		SimBattle.override_status_turns(cell["ab_status_turns"])
	var max_turns := int(cell.get("max_turns", SimBattle.MAX_TURNS))
	var agg := {"n": 0, "wins": 0, "timeouts": 0, "turns": 0, "p_alive": 0.0, "p_hp": 0.0, "e_alive": 0.0, "ids": {}, "abs": {}, "raw": [], "houses_lost": 0, "houses_total": 0}
	for i in range(int(cell["from"]), int(cell["to"])):
		var seed_ := int(cell["seed"]) + i
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_ * 7919 + 3
		var p_ids := _party(cell["party"], rng)
		var e_ids := _enemies(cell["enemy"], rng)
		var emods: Dictionary = cell.get("e_mods", {})
		var mult := 1.0
		if cell.has("e_mult_range"):   # Staerkefaktor je Kampf zufaellig (fuer die Staerke-Verhaeltnis-Messung)
			mult = snappedf(rng.randf_range(float(cell["e_mult_range"][0]), float(cell["e_mult_range"][1])), 0.05)
			emods = {"hp": mult, "atk": mult}
		var lo: Dictionary = cell.get("loadout", {})
		var p_units := _units(p_ids, cell.get("p_mods", {}))
		var emap: Dictionary = lo.get("equip_map", {})
		for k in p_units.size():
			p_units[k]["equip"] = (emap.get(p_ids[k], []) as Array).duplicate()
		if lo.has("equip_one"):   # ein Ausruestungsstueck an eine zufaellige, passende Figur der Gruppe
			var elig: Array = []
			var iid: String = lo["equip_one"]
			var req: String = Items.equipment()[iid].get("req", "")
			for k in p_units.size():
				var ud: Dictionary = SimBattle.defs()[p_ids[k]]
				if req == "" or (req == "magic" and ud.get("dmg_type", "body") == "magic") or (req == "ranged" and int(ud["range"]) > 1):
					elig.append(k)
			if not elig.is_empty():
				p_units[elig[rng.randi() % elig.size()]]["equip"].append(iid)
		var spec := {
			"map": cell.get("map", "open"),
			"inventory": lo.get("inventory", {}),
			"players": p_units,
			"enemies": _units(e_ids, emods),
			"disabled": cell.get("disabled", {}),
			"p_ai": cell.get("p_ai", {}), "e_ai": cell.get("e_ai", {}),
		}
		var b := SimSetup.build(spec, seed_)
		var w := b.play(max_turns)
		var res := b.result(w)
		_add(agg, res, p_ids, e_ids, bool(cell.get("raw", false)), mult)
	return agg


func _add(agg: Dictionary, res: Dictionary, p_ids: Array, e_ids: Array, raw: bool, mult := 1.0) -> void:
	agg["n"] += 1
	agg["houses_lost"] += int(res.get("houses_lost", 0))
	agg["houses_total"] += int(res.get("houses_total", 0))
	var w: String = res["winner"]
	if w == "p":
		agg["wins"] += 1
	elif w == "timeout":
		agg["timeouts"] += 1
	agg["turns"] += res["turns"]
	var p_total := 0
	var p_alive := 0
	var p_hp := 0.0
	var e_total := 0
	var e_alive := 0
	for r: Dictionary in res["units"]:
		var key := "%s:%s" % [r["team"], r["id"]]
		if not agg["ids"].has(key):
			agg["ids"][key] = {"n": 0, "wins": 0, "alive": 0, "dealt": 0, "taken": 0, "healed": 0, "kills": 0, "hp": 0.0}
		var s: Dictionary = agg["ids"][key]
		s["n"] += 1
		s["wins"] += 1 if w == r["team"] else 0
		s["alive"] += 1 if r["alive"] else 0
		s["dealt"] += r["dealt"]
		s["taken"] += r["taken"]
		s["healed"] += r["healed"]
		s["kills"] += r["kills"]
		s["hp"] += r["hp"]
		for tag: String in r["ab"]:
			var ak := "%s/%s" % [r["id"], tag]
			if not agg["abs"].has(ak):
				agg["abs"][ak] = {"uses": 0, "dmg": 0, "heal": 0, "status": 0, "kills": 0, "battles": 0}
			var a: Dictionary = agg["abs"][ak]
			var rs: Dictionary = r["ab"][tag]
			a["uses"] += rs["uses"]
			a["dmg"] += rs["dmg"]
			a["heal"] += rs["heal"]
			a["status"] += rs["status"]
			a["kills"] += rs["kills"]
			a["battles"] += 1
		if r["team"] == "p":
			p_total += 1
			p_alive += 1 if r["alive"] else 0
			p_hp += r["hp"]
		else:
			e_total += 1
			e_alive += 1 if r["alive"] else 0
	agg["p_alive"] += float(p_alive) / maxf(1.0, p_total)
	agg["p_hp"] += p_hp / maxf(1.0, p_total)
	agg["e_alive"] += float(e_alive) / maxf(1.0, e_total)
	if raw:
		agg["raw"].append([p_ids, e_ids, w, res["turns"], p_alive, mult])
