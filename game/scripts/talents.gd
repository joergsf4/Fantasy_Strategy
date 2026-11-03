class_name Talents
extends RefCounted
## Talentpunkte: Die Gruppe steigt je Mission eine Stufe auf, alle drei Stufen gibt es einen Punkt (nur fuer Helden der Gruppe); jeder verteilt ihn selbst
## auf vier Felder: Leben (hp), Angriff (atk), Faehigkeit 1 (a1) und Faehigkeit 2 (a2), je Rang 1 bis 3. Reine Regeln ohne Szene
## (Battle, Camp, Party und der Simulator nutzen sie). Werte stehen in data/progression.json unter "talents".

const KEYS := ["hp", "atk", "a1", "a2"]


static func cfg() -> Dictionary:
	return Progression.data()["talents"]


static func max_rank() -> int:
	return int(cfg()["max_rank"])


## Verteilte Punkte insgesamt.
static func spent(t: Dictionary) -> int:
	var n := 0
	for k: String in KEYS:
		n += int(t.get(k, 0))
	return n


static func hp_bonus(t: Dictionary) -> int:
	return int(t.get("hp", 0)) * int(cfg()["hp_per_rank"])


static func atk_bonus(t: Dictionary) -> int:
	return int(t.get("atk", 0)) * int(cfg()["atk_per_rank"])


## Faehigkeit des Felds a1 oder a2 dieses Helden (leer, wenn er nur eine hat).
static func ability_of(unit_def: Dictionary, key: String) -> String:
	var list: Array = unit_def.get("abilities", [])
	var i := 0 if key == "a1" else 1
	return str(list[i]) if i < list.size() else ""


## Faehigkeit auf Rang r bringen (Kopie), ohne die Abklingzeit anzutasten: Rang 1 Wirkung +20 % (Schaden, Heilung; ohne beides +1 Runde Statusdauer);
## Rang 2 Reichweite +1 oder Umkreis +1 (sonst +1 Runde Statusdauer, sonst +10 % Wirkung); Rang 3 nochmals Wirkung +20 %.
static func ranked(ab: Dictionary, rank: int) -> Dictionary:
	var a := ab.duplicate(true)
	if rank >= 1:
		_boost(a, float(cfg()["ability_boost"]), true)
	if rank >= 2:
		var r: Array = a.get("range", [])
		if r.size() == 2 and int(r[1]) >= 2:
			a["range"] = [int(r[0]), int(r[1]) + 1]
		elif a.has("area") and int((a["area"] as Dictionary).get("r", 0)) >= 1:
			(a["area"] as Dictionary)["r"] = int(a["area"]["r"]) + 1
		elif not _more_status(a):
			_boost(a, float(cfg()["ability_boost_rank2"]), false)
	if rank >= 3:
		_boost(a, float(cfg()["ability_boost"]), true)
	return a


## Schaden und Heilung um den Faktor erhoehen; wenn die Faehigkeit weder Schaden noch Heilung macht und status_fallback gesetzt ist, dauert der Status 1 Runde laenger.
static func _boost(a: Dictionary, f: float, status_fallback: bool) -> bool:
	var changed := false
	for ef: Dictionary in a.get("effects", []):
		match ef.get("type", ""):
			"damage":
				ef["mult"] = snappedf(float(ef["mult"]) * f, 0.01)
				changed = true
			"heal":
				ef["amount"] = ceili(float(ef.get("amount", 0)) * f)
				changed = true
	if not changed and status_fallback:
		changed = _more_status(a)
	return changed


## Alle Status der Faehigkeit dauern eine Runde laenger (hoechstens 6). true = es gab einen Status.
static func _more_status(a: Dictionary) -> bool:
	var changed := false
	for ef: Dictionary in a.get("effects", []):
		if ef.get("type", "") == "status" and int(ef.get("turns", 0)) >= 1 and int(ef["turns"]) < 6:
			ef["turns"] = int(ef["turns"]) + 1
			changed = true
	return changed


## Alle Faehigkeits-Raenge des Helden auf die Faehigkeitentabelle (Kopie je Kampf) anwenden. exclude: Faehigkeiten, die auch Gegner nutzen (nicht veraendern).
static func apply_to_abilities(table: Dictionary, hero_talents: Dictionary, unit_def: Dictionary, exclude: Array = []) -> void:
	for key: String in ["a1", "a2"]:
		var rank := int(hero_talents.get(key, 0))
		var id := ability_of(unit_def, key)
		if rank > 0 and id != "" and table.has(id) and not exclude.has(id):
			var keep_id: String = table[id].get("id", id)
			table[id] = ranked(table[id], rank)
			table[id]["id"] = keep_id


## Was der naechste Rang bringt, als Text ("Schaden ×1,6 → ×2,0", "Reichweite 2–4 → 2–5").
static func next_rank_text(ab: Dictionary, rank: int) -> String:
	if rank >= max_rank():
		return "Höchster Rang"
	var cur := ranked(ab, rank)
	var nxt := ranked(ab, rank + 1)
	var parts: PackedStringArray = []
	var ce: Array = cur.get("effects", [])
	var ne: Array = nxt.get("effects", [])
	for i in mini(ce.size(), ne.size()):
		var c: Dictionary = ce[i]
		var n: Dictionary = ne[i]
		if c.get("type", "") == "damage" and float(c["mult"]) != float(n["mult"]):
			parts.append("Schaden ×%s → ×%s" % [str(c["mult"]).replace(".", ","), str(n["mult"]).replace(".", ",")])
		elif c.get("type", "") == "heal" and int(c.get("amount", 0)) != int(n.get("amount", 0)):
			parts.append("Heilung %d → %d" % [int(c["amount"]), int(n["amount"])])
		elif c.get("type", "") == "status" and int(c.get("turns", 0)) != int(n.get("turns", 0)):
			parts.append("Dauer %d → %d Runden" % [int(c["turns"]), int(n["turns"])])
	var cr: Array = cur.get("range", [])
	var nr: Array = nxt.get("range", [])
	if cr.size() == 2 and nr.size() == 2 and int(cr[1]) != int(nr[1]):
		parts.append("Reichweite %d–%d → %d–%d" % [int(cr[0]), int(cr[1]), int(nr[0]), int(nr[1])])
	if cur.has("area") and nxt.has("area") and int(cur["area"].get("r", 0)) != int(nxt["area"].get("r", 0)):
		parts.append("Umkreis %d → %d" % [int(cur["area"]["r"]), int(nxt["area"]["r"])])
	return ", ".join(parts) if not parts.is_empty() else "Stärker"


## Verteilung fuer den Simulator und neue Helden: der Reihe nach Leben, Faehigkeit 1, Angriff, Faehigkeit 2, bis die Punkte weg sind.
static func default_allocation(points: int) -> Dictionary:
	var t := {"hp": 0, "atk": 0, "a1": 0, "a2": 0}
	var order := ["hp", "a1", "atk", "a2"]
	var i := 0
	while points > 0 and spent(t) < max_rank() * order.size():
		var k: String = order[i % order.size()]
		if int(t[k]) < max_rank():
			t[k] = int(t[k]) + 1
			points -= 1
		i += 1
	return t
