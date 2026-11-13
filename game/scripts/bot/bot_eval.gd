class_name BotEval
extends RefCounted
## Bewertung fuer den Spieltest-Bot (PlayBot): fuer eine Figur alle erreichbaren Felder und alle Aktionen, die das Aktionsmenue
## anbietet (Angriff, Heilen, Faehigkeit, Gegenstand, Feuer loeschen, Objekt-Aktionen, Verteidigen, Warten).
## Die Ideen stammen aus der Simulations-KI (game/sim/sim_ai.gd), gerechnet wird aber mit den Funktionen des echten Kampfs
## (forecast, _attack_targets, _ab_targets, _effect_targets ...). Hypothetische Felder: u["pos"] wird kurz auf das Probefeld gesetzt.
##
## Plan: {unit, tile, kind, score, target?, ab?, item?, obj?, menu?, tile_target?}
##   kind: attack | attack_obj | heal | ability | ability_obj | ability_tile | item | item_obj | douse | menu | defend | wait


static func uvalue(u: Dictionary) -> float:
	return float(u["maxhp"]) * 0.35 + float(u["atk"]) * 2.0 + float(u["def"] + u.get("res", 0)) * 0.8


static func val_damage(e: Dictionary, dmg: int) -> float:
	var d := mini(dmg, int(e["hp"]))
	var s := float(d) + (1.0 - float(e["hp"]) / float(e["maxhp"])) * 1.5
	if dmg >= int(e["hp"]):
		s += 4.0 + uvalue(e) * 0.3
	return s


static func status_value(b: Battle, u: Dictionary, v: Dictionary, ef: Dictionary) -> float:
	var mods: Dictionary = ef.get("mods", {})
	var foe: bool = v["team"] != u["team"]
	match str(ef.get("id", "")):
		"poison":
			return 0.0 if Status.has(v, "poison") or not foe else minf(12.0, float(v["hp"]) * 0.8)
		"taunt":
			return 0.0 if not foe or Status.has(v, "taunt") else 3.0 + (3.0 if int(u["def"]) >= 5 else 0.0)
		"stun":
			return float(v["atk"]) * 0.9 if foe else 0.0
		"buff":
			if foe:
				return 0.0
			var val := float(mods.get("atk", 0)) * 1.2 + float(mods.get("def", 0)) * 0.8 + float(mods.get("move", 0)) * 0.6
			for o in b.units:
				if o["team"] != v["team"] and Grid.dist(o["pos"], v["pos"]) <= int(v["move"]) + int(v["range"]) + 2:
					return val
			return val * 0.3
		"stealth":
			return 3.0 if not foe else 0.0
		"scared", "verwirrt":
			return float(v["atk"]) * 0.8 if foe else 0.0
		"angst":
			return float(v["atk"]) * 1.2 if foe else 0.0
		"schild":
			return float(v["maxhp"]) * 0.3 if not foe and not Status.has(v, "schild") else 0.0
		"brennen":
			return 6.0 if foe and not Status.has(v, "brennen") else 0.0
		"uebel":
			return 3.0 if foe else 0.0
		"tempo":
			return 2.0 if not foe else 0.0
		"tired":
			return float(mods.get("def", 0)) * 1.5 if foe else 0.0
		"wut":      # Elisabeths Wutanfall: doppelter Schaden, greift aber zufaellige Ziele an (auch Freunde)
			if foe or Status.has(v, "wut"):
				return 0.0
			var near_foes := 0
			var near_friends := 0
			var vips := BotGoals.vip_ids(b)
			for o in b.units:
				if o != v and Grid.dist(o["pos"], v["pos"]) <= Combat.move_of(v) + int(v["range"]):
					if o["team"] == v["team"] and vips.has(o["id"]):
						return -20.0      # Schuetzling in Reichweite: kein Wutanfall
					if o["team"] != v["team"]:
						near_foes += 1
					else:
						near_friends += 1
			if near_foes == 0:
				return 0.0
			return float(v["atk"]) * 2.0 * float(near_foes) / float(near_foes + near_friends) - 2.0
	if foe:      # unbekannter Status: schwach positiv, wenn er Gegner trifft (Debuff), sonst Buff fuer Verbuendete
		return 1.0
	return 1.0


## Wert einer Faehigkeit, wenn u (bereits auf Feld t gesetzt) sie auf target einsetzt.
static func ab_value(b: Battle, u: Dictionary, ab: Dictionary, target: Dictionary) -> float:
	var total := 0.0
	var pos: Vector2i = u["pos"]
	for ef: Dictionary in ab["effects"]:
		var to: String = ef.get("to", "target")
		match ef["type"]:
			"damage":
				var hits := int(ef.get("hits", 1))
				for v in b._effect_targets(u, ab, target, to):
					if v["team"] == u["team"]:
						total -= 8.0      # eigene Leute treffen
						continue
					var fc := b.forecast(u, v, pos, float(ef.get("mult", 1.0)), float(ef.get("ignore_def", 0.0)))
					total += val_damage(v, int(fc["dmg"]) * hits)
			"splash":
				if target.is_empty():
					continue
				for o in b.units:
					if o != target and Grid.dist(o["pos"], target["pos"]) == 1:
						var fc2 := b.forecast(u, o, pos, float(ef.get("mult", 0.5)))
						total += val_damage(o, int(fc2["dmg"])) if o["team"] != u["team"] else -float(fc2["dmg"]) * 1.5
			"status":
				for v in b._effect_targets(u, ab, target, to):
					total += status_value(b, u, v, ef)
			"heal":
				for v in b._effect_targets(u, ab, target, to):
					if v["team"] != u["team"]:
						continue
					var missing: int = int(v["maxhp"]) - int(v["hp"])
					total += float(mini(int(ef.get("amount", 0)), missing)) * 0.95
					if ef.get("cleanse", false) and Status.has(v, "poison"):
						total += 6.0
			"throw":
				if target.get("team", "") != u["team"]:
					var fc3 := b.forecast(u, target, pos, float(ef.get("mult", 1.0)))
					total += val_damage(target, int(fc3["dmg"])) + float(target["atk"]) * 0.9
			"polymorph":
				total += float(target["atk"]) * 2.4 + float(target["maxhp"]) * 0.15
			"assassinate":
				if b._is_normal(target):
					total += float(target["hp"]) * 1.1 + float(target["atk"]) * 0.9
				else:
					total += val_damage(target, int(b.forecast(u, target, pos, float(ef.get("mult", 1.0)))["dmg"]))
			"jump":
				total += 0.5
			"vanish":
				total -= 5.0
	return total


## Wert einer Faehigkeit auf ein Zielfeld (Bienenkorb, Tonikum, Dampframme).
static func tile_ab_value(b: Battle, u: Dictionary, ab: Dictionary, p: Vector2i) -> float:
	var total := 0.0
	if not b._first_effect(ab, "summon_hive").is_empty():
		for e in b.units:
			if e["team"] != u["team"] and Grid.dist(e["pos"], p) <= 3:
				total += 2.5
		return minf(total, 8.0)
	if not b._first_effect(ab, "ram").is_empty():
		var d := Vector2i(signi(p.x - u["pos"].x), signi(p.y - u["pos"].y))
		var k := 1
		while u["pos"] + d * k != p + d and k < 12:
			var o := b.unit_at(u["pos"] + d * k)
			if not o.is_empty() and o["team"] != u["team"]:
				total += val_damage(o, int(b.forecast(u, o, u["pos"], float(b._first_effect(ab, "ram").get("mult", 1.0)))["dmg"]))
			k += 1
		return total
	var area := b._area_tiles(ab, p)
	for ef: Dictionary in ab["effects"]:
		for o in b.units:
			if not area.has(o["pos"]):
				continue
			var foe: bool = o["team"] != u["team"]
			match ef["type"]:
				"heal":
					if not foe:
						total += float(mini(int(ef.get("amount", 0)), int(o["maxhp"]) - int(o["hp"]))) * 0.95
				"damage":
					if foe:
						total += val_damage(o, int(b.forecast(u, o, u["pos"], float(ef.get("mult", 1.0)))["dmg"]))
				"status":
					total += status_value(b, u, o, ef)
	return total


static func item_value(b: Battle, u: Dictionary, id: String, o: Dictionary) -> float:
	var it: Dictionary = Items.consumables()[id]
	var total := 0.0
	var mine: Array = b.units.filter(func(x: Dictionary) -> bool: return x["team"] == u["team"])
	for ef: Dictionary in it.get("effects", []):
		match ef["type"]:
			"heal":
				var missing: int = int(o["maxhp"]) - int(o["hp"])
				total += float(mini(int(ef.get("amount", 0)), missing)) * 0.95
				if float(o["hp"]) < 0.4 * float(o["maxhp"]):
					total += 4.0
				if ef.get("cleanse", false) and Status.has(o, "poison"):
					total += 8.0
			"reset_cd":
				for k: String in o["cd"]:
					if int(o["cd"][k]) >= 2:
						total += 4.0
			"status":
				var vs: Array = Items.victims(id, o, mine) if ef.get("to", "target") == "area_allies" else [o]
				for v: Dictionary in vs:
					total += status_value(b, u, v, ef)
			"damage":
				if o["team"] != u["team"]:
					total += val_damage(o, int(ef.get("amount", 6)))
	return total - 3.0


## Wert, brennende Objekte zu loeschen (Haeuser zaehlen am meisten, das Pflicht-Haus "lose_if_ruin" sehr viel).
static func fire_value(b: Battle, objs: Array) -> float:
	var v := 0.0
	var must := str(b.map_data.get("lose_if_ruin", ""))
	for o: Dictionary in objs:
		v += 8.0 if o["type"] in ["house", "orphanage"] else 1.0
		if o["id"] == must:
			v += 40.0
	return v


## Bester Plan fuer u. bot liefert Stil (caution), Sperren (banned) und Hinweise. no_move: zweite Aktion ohne Bewegung.
static func best_plan(bot: PlayBot, u: Dictionary, no_move := false) -> Dictionary:
	var b := bot.b
	var orig: Vector2i = u["pos"]
	var caution := float(bot.style.get("caution", 1.0))
	var risk := 1.5 if u["role"] in ["healer", "mage", "ranged", "support"] else 1.0
	if BotGoals.vip_ids(b).has(u["id"]):
		risk *= 3.0
	if b.goal.get("type", "") == "survive":
		risk *= 1.5
	var tiles := candidate_tiles(b, u) if not no_move else [orig]
	var goal := BotGoals.target(bot, u)
	var dmap: Dictionary = _distance_map(b, goal["tile"], u)
	var threats: Array = []
	for e in b.units:
		if e["team"] != "e" or e.get("idle", false):
			continue
		var reach_d := Combat.move_of(e) + int(e["range"])
		threats.append([e["pos"], reach_d, Combat.damage(e, u, 0, 0.0), e.get("guard", false)])
	var objs := BotGoals.objectives(bot)
	var fire_t := b.world.burning_tiles()
	var uv := uvalue(u)
	var best: Dictionary = {}
	var best_s := -INF
	var reach_tile: bool = b.goal.get("type", "") == "reach" and (not b.goal.has("unit") or str(b.goal["unit"]) == u["id"])
	var goal_tiles: Array = b.goal_tiles() if reach_tile else []
	var hide_steps: bool = not (b.map_data.get("hide_steps", []) as Array).is_empty()
	for t: Vector2i in tiles:
		if not u["flying"] and t != orig and fire_t.has(t):
			continue
		u["pos"] = t
		var cover := b._cover_for(u, t)
		var danger := 0.0
		var lethal := 0.0
		for th: Array in threats:
			if Grid.dist(t, th[0]) <= int(th[1]) or (th[3] and Grid.dist(t, th[0]) <= Battle.GUARD_RADIUS + 1):
				var d := maxf(1.0, float(th[2]) - float(cover))
				danger += d * 0.5
				lethal += d
		var tile_s := float(cover) - caution * risk * danger
		if lethal >= float(u["hp"]):
			tile_s -= caution * 0.3 * uv
		var gd := float(dmap.get(t, Grid.dist(t, goal["tile"]) + 12))
		tile_s -= absf(gd - float(goal["dist"])) * float(goal["weight"])
		if goal_tiles.has(t):
			tile_s += 1000.0
		if hide_steps and t != orig:      # Versteck-Pfad (Mission 23): jedes erreichte Versteck ist Fortschritt
			tile_s += 30.0
		var acts := actions_at(bot, u, t, objs)
		for a: Dictionary in acts:
			var s: float = float(a["score"]) + tile_s
			if s > best_s:
				best_s = s
				best = a
				best["tile"] = t
		var wait_s := tile_s * 0.5 + 0.0
		if lethal >= 0.35 * float(u["hp"]):
			var tile2 := float(cover) - caution * risk * danger * Combat.defend_factor(u)
			if tile2 - tile_s * 0.0 > wait_s:
				var ds := tile2 - absf(gd - float(goal["dist"])) * float(goal["weight"]) + (1000.0 if goal_tiles.has(t) else 0.0)
				if ds > best_s:
					best_s = ds
					best = {"kind": "defend", "tile": t}
		var ws := tile_s - 0.2
		if ws > best_s:
			best_s = ws
			best = {"kind": "wait", "tile": t}
	u["pos"] = orig
	best["unit"] = u
	best["score"] = best_s
	return best


## Felder, auf die u ziehen darf (wie Battle._select: frei, erreichbar, im Versteck-Pfad nur die erlaubten).
static func candidate_tiles(b: Battle, u: Dictionary) -> Array:
	var reach := b.grid.reachable(u["pos"], Combat.move_of(u), u["flying"], b._team_tiles("e"))
	var occupied := {}
	for o in b.units:
		if o != u:
			occupied[o["pos"]] = true
	var out: Array = [u["pos"]]
	var steps: Array = b.map_data.get("hide_steps", [])
	if not steps.is_empty():
		if b.hide_i < steps.size():
			for spot: Array in steps[b.hide_i]:
				var sp := Vector2i(spot[0], spot[1])
				if reach.has(sp) and not occupied.has(sp):
					out.append(sp)
		return out
	for p: Vector2i in reach:
		if p != u["pos"] and not occupied.has(p):
			out.append(p)
	return out


## Echte Wegstrecke zum Ziel; ist es zu Fuss nicht erreichbar, ohne Hindernisse gerechnet (Durchbruch: Mauer, Tor, Bruecke).
static func _distance_map(b: Battle, goal: Vector2i, u: Dictionary) -> Dictionary:
	var dm := b.grid.reachable(goal, 80, u["flying"], {})
	if dm.has(u["pos"]) or u["flying"]:
		return dm
	var saved := b.grid.blocked
	b.grid.blocked = {}
	dm = b.grid.reachable(goal, 80, true, {})
	b.grid.blocked = saved
	return dm


## Alle Aktionen, die das Menue von Feld t aus anbietet (u steht schon auf t), mit Wert.
static func actions_at(bot: PlayBot, u: Dictionary, t: Vector2i, objs: Array) -> Array:
	var b := bot.b
	var out: Array = []
	var gtype: String = b.goal.get("type", "rout")
	var focus := str(b.goal.get("unit", "")) if gtype == "defeat" else ""
	for e in b._attack_targets(u, t):
		var fc := b.forecast(u, e, t)
		var s := val_damage(e, int(fc["dmg"])) - maxf(float(fc["counter"]), 0.0) * 0.6 + 1.0
		if e["id"] == focus:
			s *= 2.5
		out.append({"kind": "attack", "target": e, "score": s})
	for o in b._attack_objs(u, t):
		var so := _obj_attack_value(bot, u, o)
		if so > 0.0:
			out.append({"kind": "attack_obj", "obj": o, "score": so})
	for a in b._heal_targets(u, t):
		var missing: int = int(a["maxhp"]) - int(a["hp"])
		var sh := float(mini(int(u["heal"]), missing)) * 0.95 + (6.0 if Status.has(a, "poison") else 0.0)
		if BotGoals.vip_ids(b).has(a["id"]):
			sh *= 1.6
		out.append({"kind": "heal", "target": a, "score": sh})
	for id: String in u["abilities"]:
		if int(u["cd"].get(id, 0)) > 0 or bot.is_banned(u, id):
			continue
		var ab: Dictionary = b.abilities[id]
		var pen := float(ab.get("cd", 0)) * 0.5
		var offered := false
		if ab["target"] == "tile":
			for p: Vector2i in b._ab_tiles(u, id, t):
				offered = true
				out.append({"kind": "ability_tile", "ab": id, "tile_target": p, "score": tile_ab_value(b, u, ab, p) - pen})
		else:
			for o in b._ab_targets(u, id, t):
				offered = true
				if ab["target"] == "enemy" and o["team"] == u["team"]:
					continue      # Wurf auf Verbuendete und geheime Interaktionen spielt der Bot nicht
				var sa := ab_value(b, u, ab, o) - pen
				if o.get("id", "") == focus:
					sa *= 2.0
				out.append({"kind": "ability", "ab": id, "target": o, "score": sa})
		for ob in b._obj_targets(u, id, t):
			offered = true
			var sv := _obj_ability_value(bot, u, id, ob) - pen
			if sv > 0.0:
				out.append({"kind": "ability_obj", "ab": id, "obj": ob, "score": sv})
		if offered:
			bot.note_offered(u, id)
	for iid: String in b.inventory:
		if int(b.inventory[iid]) <= 0 or not Items.consumables().has(iid):
			continue
		for o in b._item_targets(u, iid):
			out.append({"kind": "item", "item": iid, "target": o, "score": item_value(b, u, iid, o)})
	var burning := b._douse_targets(u)
	if not burning.is_empty():
		for o in burning:
			out.append({"kind": "douse", "obj": o, "score": fire_value(b, [o]) - 0.5})
	for ob: Dictionary in objs:
		var o: Dictionary = ob["obj"]
		if ob["actor"] != "" and ob["actor"] != u["id"]:
			continue
		var d := Grid.dist(t, o["pos"])
		if (ob["adj"] and d != 1) or (not ob["adj"] and d != 0):
			continue
		if ob["kind"] == "hostage":
			var opt := b._hostage_option(o)
			if not opt["enabled"]:
				continue
			out.append({"kind": "menu", "menu": str(opt["text"]), "score": float(ob["value"])})
		else:
			out.append({"kind": "menu", "menu": str(ob["kind"]), "score": float(ob["value"])})
	if gtype in ["free", "free_all"]:      # Anker: neben einer angefangenen Geisel stehen bleiben, sonst ziehen sich die Fesseln zu
		for o in b.world.objects:
			if o["type"] == "hostage" and o["state"] == "bound" and int(o.get("progress", 0)) > 0 and Grid.dist(t, o["pos"]) == 1:
				out.append({"kind": "defend", "score": 20.0})
	var rp := b._reprogram_target(u)
	if not rp.is_empty() and b.capture_turn != b.turn:
		out.append({"kind": "menu", "menu": "Umprogrammieren", "score": 200.0})
	var ch := b._chest_at(t)
	if not ch.is_empty() and not ch["open"]:
		out.append({"kind": "menu", "menu": "Truhe öffnen", "score": 3.0})
	var vl := b._village_at(t)
	if not vl.is_empty() and not vl["visited"]:
		out.append({"kind": "menu", "menu": "Dorf besuchen", "score": 3.0})
	return out


## Wert, ein Objekt anzugreifen: Bienenstoecke, Hindernisse auf dem Weg zum Ziel, Geraete, deren Zerstoerung etwas ausloest.
static func _obj_attack_value(bot: PlayBot, u: Dictionary, o: Dictionary) -> float:
	var b := bot.b
	var hd: int = World.hit_damage(o, Combat.stat(u, "atk"))
	var base := minf(float(hd), float(o["hp"])) * 0.8 + (8.0 if hd >= int(o["hp"]) else 0.0)
	match o["type"]:
		"hive":
			return base if o["state"] == "active" else 0.0
		"gate", "wall", "crate", "zylinder", "maschine", "geraet", "cage":
			var w := 0.4
			for h: Dictionary in bot.hints.get("objectives", []):
				if str(h.get("object", "")) == o["id"]:
					w = float(h.get("weight", 10.0)) / 10.0
			if _blocks_goal(bot, u):
				w = maxf(w, 1.0)
			return base * w
	return base * 0.3


## Ist das Ziel der Figur zu Fuss nicht erreichbar (Mauer, Tor, Bruecke)?
static func _blocks_goal(bot: PlayBot, u: Dictionary) -> bool:
	var g := BotGoals.target(bot, u)
	var dm := bot.b.grid.reachable(g["tile"], 80, u["flying"], {})
	return not dm.has(u["pos"])


static func _obj_ability_value(bot: PlayBot, u: Dictionary, id: String, o: Dictionary) -> float:
	var b := bot.b
	if b.world.is_burning(o):
		var group: Array = b.world.objects.filter(func(x: Dictionary) -> bool: return b.world.is_burning(x) and Grid.dist(x["pos"], o["pos"]) <= 1)
		return fire_value(b, group)
	return _obj_attack_value(bot, u, o) * 1.2
