class_name BotGoals
extends RefCounted
## Zielplaner des Spieltest-Bots: wohin soll eine Figur, und welche Objekte sind gerade wichtig?
## Liest das Missionsziel (b.goal) bei jeder Entscheidung neu, damit Zielwechsel per Ereignis (Rueckblende) sofort greifen.
## Rueckgabe von target(): {"tile": Vector2i, "dist": gewuenschte Entfernung, "weight": Gewicht der Annaeherung}


## Lebende, sichtbare Gegner, die man angreifen kann.
static func foes(b: Battle) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in b.units:
		if e["team"] == "e" and b._hittable(e) and not Status.has(e, "stealth"):
			out.append(e)
	return out


## Figur, die nicht fallen darf (Kartenfeld lose_if_fallen, Ziel reach mit unit, capture mit by).
static func vip_ids(b: Battle) -> Array:
	var out: Array = []
	if str(b.map_data.get("lose_if_fallen", "")) != "":
		out.append(str(b.map_data["lose_if_fallen"]))
	if b.goal.get("type", "") == "reach" and b.goal.has("unit"):
		out.append(str(b.goal["unit"]))
	if b.goal.get("type", "") == "capture" and b.goal.has("by"):
		out.append(str(b.goal["by"]))
	return out


## Ziel-Objekte, an denen eine Figur etwas tun kann: [{obj, kind, actor, value, adj}].
## adj: true = daneben stehen (Glocke, Honig, Geisel), false = darauf stehen (Schalter).
static func objectives(bot: PlayBot) -> Array:
	var b := bot.b
	var out: Array = []
	var gtype: String = b.goal.get("type", "rout")
	for o in b.world.objects:
		match o["type"]:
			"bell":
				if o["state"] == "ready":
					out.append({"obj": o, "kind": "Glocke läuten", "actor": "", "value": 18.0, "adj": true})
			"honigmaschine":
				if o["state"] == "empty":
					out.append({"obj": o, "kind": "Honig einfüllen", "actor": "bienenmaedchen", "value": 60.0, "adj": true})
			"switch":
				if o["state"] == "off":
					out.append({"obj": o, "kind": "Schalter umlegen", "actor": "", "value": 10.0, "adj": false})
			"hostage":
				if o["state"] == "bound" and not o.get("locked", false):
					var v := 45.0 if gtype in ["free", "free_all"] else 12.0
					out.append({"obj": o, "kind": "hostage", "actor": "", "value": v, "adj": true})
	for h: Dictionary in bot.hints.get("objectives", []):      # Missionshinweise (data/bot_hints.json)
		var ho := b.world.by_id(str(h.get("object", "")))
		if ho.is_empty() or int(h.get("from_turn", 1)) > b.turn:
			continue
		for x: Dictionary in out:
			if x["obj"] == ho:
				x["value"] = float(h.get("weight", x["value"]))
				if h.has("by"):
					x["actor"] = str(h["by"])
	return out


## Positionen ungefeuerter Ausloeser, die durch Herangehen ausgeloest werden (Erkunden in ch19, ch24).
static func explore_tiles(b: Battle) -> Array:
	var out: Array = []
	for t: Dictionary in b.triggers:
		if t.get("fired", false):
			continue
		var w: Dictionary = t["when"]
		if w.has("enter"):
			out.append(Vector2i(w["enter"][0], w["enter"][1]))
		if w.has("near_object"):
			var o := b.world.by_id(str(w["near_object"].get("id", w["near_object"].get("object", ""))))
			if not o.is_empty():
				out.append(o["pos"])
	return out


## Wohin soll Figur u, wenn sie nichts Besseres zu tun hat?
static func target(bot: PlayBot, u: Dictionary) -> Dictionary:
	var b := bot.b
	var g: Dictionary = b.goal
	var gtype: String = g.get("type", "rout")
	if gtype == "reach":
		var tiles := b.goal_tiles()
		if g.has("unit") and u["id"] != str(g["unit"]):      # Begleiter: bei der Figur bleiben, die ankommen muss
			var vip := b._find(str(g["unit"]))
			if not vip.is_empty():
				return {"tile": vip["pos"], "dist": 1, "weight": 0.6}
		return {"tile": _nearest(u["pos"], tiles), "dist": 0, "weight": 3.0}
	if u["id"] == str(b.map_data.get("lose_if_fallen", "")):      # Schuetzling (Regent in Mission 19): haelt sich heraus
		return {"tile": u["pos"], "dist": 0, "weight": 0.0}
	if gtype == "capture" and u["id"] == str(g.get("by", "")):
		var cu := b._find(str(g["unit"]))
		if not cu.is_empty() and cu["team"] == "e":
			return {"tile": cu["pos"], "dist": 1, "weight": 4.0}
	for ob: Dictionary in objectives(bot):      # Objekt-Aufgaben: die passende Figur laeuft hin
		if ob["actor"] != "" and ob["actor"] != u["id"]:
			continue
		if ob["value"] >= 30.0 or (ob["actor"] == u["id"] and ob["actor"] != ""):
			if _closest_capable(bot, ob) == u:
				return {"tile": ob["obj"]["pos"], "dist": 1 if ob["adj"] else 0, "weight": 3.0}
	var fs := foes(b)
	if fs.is_empty() or (gtype == "rout_spawned" and not b.enemy_spawned):
		var ex := explore_tiles(b)
		if not ex.is_empty():
			return {"tile": _nearest(u["pos"], ex), "dist": 0, "weight": 1.5}
	if u["heal"] > 0 and u["role"] == "healer":
		var worst: Dictionary = {}
		var ratio := 1.0
		for a in b.units:
			if a["team"] == "p" and a != u:
				var r := float(a["hp"]) / float(a["maxhp"])
				if r < ratio:
					ratio = r
					worst = a
		if not worst.is_empty() and ratio < 0.8:
			return {"tile": worst["pos"], "dist": 1, "weight": 1.0}
	var near: Dictionary = {}
	var nd := 999
	var focus := ""
	if gtype == "defeat":
		focus = str(g.get("unit", ""))
	for e in fs:
		var d := Grid.dist(u["pos"], e["pos"])
		if e["id"] == focus:
			d -= 6
		if d < nd:
			nd = d
			near = e
	if near.is_empty():
		return {"tile": u["pos"], "dist": 0, "weight": 0.0}
	var desired := 1
	if int(u["range"]) > 1:
		desired = int(u["range"])
	return {"tile": near["pos"], "dist": desired, "weight": 1.0}


static func _closest_capable(bot: PlayBot, ob: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var bd := 999
	for a in bot.b.units:
		if a["team"] != "p" or (ob["actor"] != "" and a["id"] != ob["actor"]):
			continue
		var d := Grid.dist(a["pos"], ob["obj"]["pos"])
		if d < bd:
			bd = d
			best = a
	return best


static func _nearest(from: Vector2i, tiles: Array) -> Vector2i:
	var best: Vector2i = from
	var bd := 999
	for t: Vector2i in tiles:
		var d := Grid.dist(from, t)
		if d < bd:
			bd = d
			best = t
	return best
