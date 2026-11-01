class_name SimAI
extends RefCounted
## Einfache, regelkonforme Spielweise fuer beide Seiten: pro Figur werden alle erreichbaren Felder und alle Aktionen
## (Angriff, Heilen, Faehigkeit, Warten) mit den echten Schadensregeln bewertet und die beste gewaehlt.
## Bewertet wird in "Lebenspunkt-Aequivalenten". Keine Sonderbehandlung einzelner Faehigkeiten:
## alles wird aus den Effekten in abilities.json abgeleitet. Wichtig fuer sauberes Balancing.
##
## Parameter je Team (SimBattle.ai_cfg): caution (Vorsicht, 1.0), noise (Chance auf eine der 3 besten
## statt der besten Aktion, 0.0).


static func uvalue(u: Dictionary) -> float:
	return float(u["maxhp"]) * 0.35 + float(u["atk"]) * 2.0 + float(u["def"] + u["res"]) * 0.8


static func take_turn(b: SimBattle, u: Dictionary) -> void:
	var act := choose(b, u, false)
	execute(b, u, act, false)
	if act.get("free", false) and b.units.has(u):
		var act2 := choose(b, u, true)
		execute(b, u, act2, true)


static func execute(b: SimBattle, u: Dictionary, act: Dictionary, moved: bool) -> void:
	if not moved:
		b.move_to(u, act["tile"])
	match act["kind"]:
		"attack":
			b.attack(u, act["target"])
		"heal":
			b.heal_basic(u, act["target"])
		"ability":
			b.run_ability(u, act["ab"], act["target"])
		"item":
			b.use_item(u, act["item"], act["target"])
		"defend":
			b.defend(u)
		"wait":
			b._ab_stat(u, "_wait")["uses"] += 1
			if SimBattle.wait_atk > 0 and u["team"] == "p":    # nur die Spielerseite: Warten ist dort eine bewusste Wahl
				Status.add(u, "wachsam", 1, {"atk": SimBattle.wait_atk})    # wie im Spiel: Warten macht wachsam
		"hive":
			b.attack_hive(u, act["obj"])
		"douse":
			b.douse(u, act["obj"])
		"ab_obj":
			b.extinguish_ability(u, act["ab"], act["obj"])


static func _val_damage(e: Dictionary, dmg: int) -> float:
	var d := mini(dmg, e["hp"])
	var s := float(d) + (1.0 - float(e["hp"]) / float(e["maxhp"])) * 1.5
	if dmg >= e["hp"]:
		s += 4.0 + uvalue(e) * 0.3
	return s


static func _status_value(b: SimBattle, u: Dictionary, v: Dictionary, ef: Dictionary) -> float:
	var mods: Dictionary = ef.get("mods", {})
	match ef["id"]:
		"poison":
			return 0.0 if Status.has(v, "poison") else minf(12.0, float(v["hp"]) * 0.8)
		"taunt":
			if v["team"] == u["team"] or Status.has(v, "taunt"):
				return 0.0
			return 3.0 + (3.0 if u["def"] >= 5 else 0.0)
		"stun":
			return float(v["atk"]) * 0.9
		"buff":
			if v["team"] != u["team"]:
				return 0.0
			var val := float(mods.get("atk", 0)) * 1.2 + float(mods.get("def", 0)) * 0.8
			var engaged := false
			for o in b.units:
				if o["team"] != v["team"] and Grid.dist(o["pos"], v["pos"]) <= v["move"] + v["range"] + 2:
					engaged = true
					break
			return val if engaged else val * 0.3
		"stealth":
			return 3.0
		"scared":
			return float(v["atk"]) * 0.8 if v["team"] != u["team"] else 0.0
		"angst":
			return float(v["atk"]) * 1.2 if v["team"] != u["team"] else 0.0
		"schild":
			return float(v["maxhp"]) * 0.3 if v["team"] == u["team"] and not Status.has(v, "schild") else 0.0
		"brennen":
			return 6.0 if v["team"] != u["team"] and not Status.has(v, "brennen") else 0.0
		"uebel":
			return 3.0 if v["team"] != u["team"] else 0.0
		"tempo":
			return 2.0 if v["team"] == u["team"] else 0.0
		"tired":
			return float(mods.get("def", 0)) * 1.5
	return 0.0


## Wert einer Faehigkeit, wenn u sie von Feld t aus auf target einsetzt.
static func ab_value(b: SimBattle, u: Dictionary, ab: Dictionary, target: Dictionary, t: Vector2i) -> float:
	var pos := t
	var total := 0.0
	for ef: Dictionary in ab["effects"]:
		match ef["type"]:
			"jump":
				pos = target["pos"] + (target["pos"] - pos)
			"damage":
				var hits := int(ef.get("hits", 1))
				for v in b.effect_victims(u, ab, target, ef.get("to", "target"), pos):
					var fc := b.forecast(u, v, pos, ef["mult"], ef.get("ignore_def", 0.0))
					total += _val_damage(v, fc["dmg"] * hits)
			"splash":
				for o in b.units:
					if o["team"] != u["team"] and o != target and Grid.dist(o["pos"], target["pos"]) == 1:
						var fc2 := b.forecast(u, o, pos, ef["mult"])
						total += _val_damage(o, fc2["dmg"])
			"status":
				for v in b.effect_victims(u, ab, target, ef.get("to", "target"), pos):
					total += _status_value(b, u, v, ef)
			"heal":
				for v in b.effect_victims(u, ab, target, ef.get("to", "target"), pos):
					var missing: int = v["maxhp"] - v["hp"]
					total += float(mini(int(ef["amount"]), missing)) * 0.95
					if ef.get("cleanse", false) and Status.has(v, "poison"):
						total += 6.0
			"throw":
				var fc3 := b.forecast(u, target, pos, ef["mult"])
				total += _val_damage(target, fc3["dmg"]) + float(target["atk"]) * 0.9
			"polymorph":
				total += float(target["atk"]) * 2.4 + float(target["maxhp"]) * 0.15
			"assassinate":
				total += float(target["hp"]) * 1.1 + float(target["atk"]) * 0.9 if b.is_normal(target) else float(b.forecast(u, target, pos, ef["mult"])["dmg"])
	return total


## Wert, eine Gruppe brennender Objekte zu loeschen: gerettete Haeuser zaehlen am meisten, dazu Schutz der Umgebung.
static func _fire_value(b: SimBattle, objs: Array) -> float:
	var v := 0.0
	for o: Dictionary in objs:
		if o["type"] == "house":
			v += 8.0
		else:
			v += 1.0
		for d: Vector2i in World.DIRS4:
			var n: Dictionary = b.world.at(o["pos"] + d)
			if not n.is_empty():
				if n["type"] == "house" and n["state"] == "intact":
					v += 3.0
			elif b.flammable.has(o["pos"] + d):
				v += 0.8
	return v


## Wert eines Verbrauchsgegenstands auf ein Ziel. Gegenstaende sind knapp: ein fester Abzug verhindert Verschwendung.
static func item_value(b: SimBattle, u: Dictionary, id: String, o: Dictionary) -> float:
	var it: Dictionary = Items.consumables()[id]
	var total := 0.0
	var mine := b.units.filter(func(x: Dictionary) -> bool: return x["team"] == u["team"])
	for ef: Dictionary in it["effects"]:
		match ef["type"]:
			"heal":
				var missing: int = o["maxhp"] - o["hp"]
				total += float(mini(int(ef["amount"]), missing)) * 0.95
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
					total += _status_value(b, u, v, ef)
	return total - 3.0


## Beste Aktion von Feld t aus, {} wenn keine sinnvolle moeglich ist.
static func best_action_at(b: SimBattle, u: Dictionary, t: Vector2i, targets: Array[Dictionary], friends: Array[Dictionary], ready: Array) -> Dictionary:
	var best := {}
	var best_s := 0.5     # Mindestwert, damit nichts Sinnloses gewaehlt wird
	for e in targets:
		var d := Grid.dist(t, e["pos"])
		if not Combat.in_range(u, d):
			continue
		var fc := b.forecast(u, e, t)
		var s := _val_damage(e, fc["dmg"]) - maxf(float(fc["counter"]), 0.0) * 0.6 + 1.0   # +1: Vorteil des ersten Schlags
		if s > best_s:
			best_s = s
			best = {"kind": "attack", "target": e}
	if u["heal"] > 0:
		for a in friends:
			if not Combat.in_range(u, Grid.dist(t, a["pos"])):
				continue
			var missing: int = a["maxhp"] - a["hp"]
			var poisoned := Status.has(a, "poison")
			if missing <= 0 and not poisoned:
				continue
			var s2 := float(mini(u["heal"], missing)) * 0.95 + (6.0 if poisoned else 0.0)
			if s2 > best_s:
				best_s = s2
				best = {"kind": "heal", "target": a}
	var abd := SimBattle.ab_defs()
	for id: String in ready:
		var ab: Dictionary = abd[id]
		var pen := float(ab["cd"]) * 0.5
		var tgt: String = ab["target"]
		if tgt == "tile" or ab.has("ai_flee"):
			continue      # Bienenkorb, Tonikum, Flucht modelliert der Simulator nicht
		if tgt == "self":
			var s3 := ab_value(b, u, ab, u, t) - pen
			if s3 > best_s:
				best_s = s3
				best = {"kind": "ability", "ab": id, "target": u, "free": not ab.get("ends_turn", true)}
			continue
		var r: Array = ab["range"]
		var pool: Array[Dictionary] = targets if tgt == "enemy" else friends
		if tgt == "ally_center":
			pool = friends.duplicate()
			pool.append(u)
		for o in pool:
			var dd := Grid.dist(t, o["pos"])
			if dd < r[0] or dd > r[1]:
				continue
			if tgt == "enemy":
				if ab.has("require_tag") and not (o["tags"] as Array).has(ab["require_tag"]):
					continue
				if ab.get("shape", "") == "line" and o["pos"].x != t.x and o["pos"].y != t.y:
					continue
				if not b.first_effect(ab, "jump").is_empty() and not b.tile_free(o["pos"] + (o["pos"] - t), u):
					continue
			elif tgt == "ally" and not b.first_effect(ab, "heal").is_empty():
				if not (o["hp"] < o["maxhp"] or Status.has(o, "poison")):
					continue
			var s4 := ab_value(b, u, ab, o, t) - pen
			if s4 > best_s:
				best_s = s4
				best = {"kind": "ability", "ab": id, "target": o, "free": not ab.get("ends_turn", true)}
	if u["team"] == "p" and not b.world.objects.is_empty() and b.ai_cfg["p"].get("douse", true):
		for o in b.world.objects:
			if not b.world.is_burning(o):
				continue
			if Grid.dist(t, o["pos"]) <= 1:
				var sd := _fire_value(b, [o]) - 0.5
				if sd > best_s:
					best_s = sd
					best = {"kind": "douse", "obj": o}
			for id: String in ready:
				if not b.obj_targets(u, id, t).has(o):
					continue
				var group: Array = b.world.objects.filter(func(x: Dictionary) -> bool: return b.world.is_burning(x) and Grid.dist(x["pos"], o["pos"]) <= 1)
				var sa := _fire_value(b, group) - float(abd[id]["cd"]) * 0.5
				if sa > best_s:
					best_s = sa
					best = {"kind": "ab_obj", "ab": id, "obj": o, "free": false}
	if u["team"] == "p" and b.ai_cfg["p"].get("hive", true):   # Bienenstoecke zerstoeren, damit keine Bienen nachschluepfen
		for o in b.world.objects:
			if o["type"] == "hive" and o["state"] == "active" and Combat.in_range(u, Grid.dist(t, o["pos"])):
				var hd: int = World.hit_damage(o, Combat.stat(u, "atk"))
				var sh := minf(float(hd), float(o["hp"])) * 0.8 + (8.0 if hd >= int(o["hp"]) else 0.0) - 0.5
				if sh > best_s:
					best_s = sh
					best = {"kind": "hive", "obj": o}
	var inv: Dictionary = b.inventory.get(u["team"], {})
	for iid: String in inv:
		if int(inv[iid]) <= 0:
			continue
		var ir: int = int(Items.consumables()[iid].get("range", 1))
		var ipool: Array[Dictionary] = friends.duplicate()
		ipool.append(u)
		for o in ipool:
			if Grid.dist(t, o["pos"]) > ir or not Items.useful_on(iid, o):
				continue
			var s6 := item_value(b, u, iid, o)
			if s6 > best_s:
				best_s = s6
				best = {"kind": "item", "item": iid, "target": o}
	if not best.is_empty():
		best["score"] = best_s
	return best


## Wohin soll gelaufen werden, wenn nichts anzugreifen ist? [Zielfeld, gewuenschte Entfernung]
static func _goal(b: SimBattle, u: Dictionary, targets: Array[Dictionary], friends: Array[Dictionary], caution: float) -> Array:
	if u["team"] == "p" and b.goal_tile.x >= 0:      # Ziel erreichen: wer nichts angreifen kann, laeuft zum Zielfeld
		return [b.goal_tile, 0]
	if u["team"] == "p" and b.ai_cfg["p"].get("douse", true):   # wer Feuer loeschen kann, laeuft zum naechsten Brand
		var can := false
		for id: String in u["abilities"]:
			if (SimBattle.ab_defs()[id].get("caps", []) as Array).has("extinguish"):
				can = true
		if can:
			var nb: Dictionary = {}
			var nd := 999
			for o in b.world.objects:
				if b.world.is_burning(o) and Grid.dist(u["pos"], o["pos"]) < nd:
					nd = Grid.dist(u["pos"], o["pos"])
					nb = o
			if not nb.is_empty():
				return [nb["pos"], 2]
	if u["heal"] > 0 and u["role"] == "healer":
		var worst: Dictionary = {}
		var ratio := 1.0
		for a in friends:
			var r := float(a["hp"]) / float(a["maxhp"])
			if r < ratio or (Status.has(a, "poison") and r <= ratio):
				ratio = r
				worst = a
		if not worst.is_empty() and ratio < 1.0:
			return [worst["pos"], 1]
		var front: Dictionary = {}
		var fd := 999
		for a in friends:
			for e in targets:
				var dd := Grid.dist(a["pos"], e["pos"])
				if dd < fd:
					fd = dd
					front = a
		if not front.is_empty():
			return [front["pos"], 2]
	var near: Dictionary = {}
	var nd := 999
	for e in targets:
		var d := Grid.dist(u["pos"], e["pos"])
		if d < nd:
			nd = d
			near = e
	if near.is_empty():
		return [u["pos"], 0]
	var desired := 1
	if u["range"] > 1 and caution > 0.3:
		desired = u["range"] + u["move"]     # nur so nah, dass man im naechsten Zug schiessen kann
	elif u["range"] > 1:
		desired = u["range"]
	return [near["pos"], desired]


static func choose(b: SimBattle, u: Dictionary, no_move: bool) -> Dictionary:
	var cfg: Dictionary = b.ai_cfg[u["team"]]
	var caution := float(cfg.get("caution", 1.0)) * clampf(1.0 - float(b.turn - 10) / 6.0, 0.0, 1.0)
	var foes := b.visible_foes(u)
	var targets: Array[Dictionary] = foes
	var forced := b.taunter(u)
	if not forced.is_empty() and foes.has(forced):
		targets = [forced]
	var friends := b.friends_of(u)
	var ready := b.ready_abilities(u)
	var reach: Dictionary = {u["pos"]: 0} if no_move else b.reach_tiles(u)
	var threats := []
	for e in b.foes_of(u):
		threats.append([e["pos"], e["move"] + e["range"], Combat.damage(e, u, 0, 0.0)])
	var can_defend: bool = cfg.get("defend", u["team"] == "p")
	var goal := _goal(b, u, targets, friends, caution)
	var dmap: Dictionary = b.grid.reachable(goal[0], 80, u["flying"], {})   # echte Wegstrecke zum Ziel (um Hindernisse herum)
	var risk := 1.5 if u["role"] in ["healer", "mage", "ranged"] else 1.0
	var cands := []
	var uv := uvalue(u)
	var fire_t := b.world.burning_tiles()
	for t: Vector2i in reach:
		if not u["flying"] and t != u["pos"] and fire_t.has(t):
			continue      # nicht ins Feuer stellen
		var cover := b.cover_for(u, t)
		var danger := 0.0
		var lethal := 0.0
		for th: Array in threats:
			if Grid.dist(t, th[0]) <= th[1]:
				var d := maxf(1.0, float(th[2]) - float(cover))
				danger += d * 0.5
				lethal += d
		var tile := float(cover) - caution * risk * danger
		if lethal >= float(u["hp"]):
			tile -= caution * 0.3 * uv
		if can_defend and lethal >= 0.35 * float(u["hp"]):   # Verteidigen nur, wenn wirklich Gefahr droht
			var fct := Combat.defend_factor(u)
			var d2 := 0.0
			var l2 := 0.0
			for th: Array in threats:
				if Grid.dist(t, th[0]) <= th[1]:
					var dd := maxf(1.0, ceilf((float(th[2]) - float(cover)) * fct))
					d2 += dd * 0.5
					l2 += dd
			var tile2 := float(cover) - caution * risk * d2
			if l2 >= float(u["hp"]):
				tile2 -= caution * 0.3 * uv
			cands.append({"kind": "defend", "tile": t, "score": tile2, "free": false})
		var act := best_action_at(b, u, t, targets, friends, ready)
		if not act.is_empty():
			act["tile"] = t
			act["score"] += tile
			cands.append(act)
		var wait_s := tile * 0.5 - absf(float(dmap.get(t, 99)) - float(goal[1]))
		cands.append({"kind": "wait", "tile": t, "score": wait_s, "free": false})
	cands.sort_custom(func(a: Dictionary, c: Dictionary) -> bool: return a["score"] > c["score"])
	var pick: Dictionary = cands[0]
	var noise := float(cfg.get("noise", 0.0))
	if noise > 0.0 and b.rng.randf() < noise:
		pick = cands[b.rng.randi_range(0, mini(2, cands.size() - 1))]
	return pick
