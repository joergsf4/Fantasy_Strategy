class_name Progression
extends RefCounted
## Fortschritt ueber die Kapitel: Erfahrung und Stufen der Helden sowie Staerkefaktoren der Gegner je Mission (data/progression.json).
## Reine Regeln ohne Szene: gemeinsam genutzt von Battle (Spiel), Party (Erfahrung) und SimBattle (Balancing).

static var _d: Dictionary = {}


static func data() -> Dictionary:
	if _d.is_empty():
		_d = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression.json"))
	return _d


static func max_level() -> int:
	return (data()["levels"]["xp"] as Array).size()


## Stufe (1 bis max) fuer so viel Erfahrung.
static func level_for_xp(xp: int) -> int:
	var lv := 1
	var table: Array = data()["levels"]["xp"]
	for i in table.size():
		if xp >= int(table[i]):
			lv = i + 1
	return lv


## Erfahrung, ab der die naechste Stufe gilt (-1 = hoechste Stufe erreicht).
static func xp_for_next(xp: int) -> int:
	var table: Array = data()["levels"]["xp"]
	var lv := level_for_xp(xp)
	return -1 if lv >= table.size() else int(table[lv])


static func xp_squad() -> int:
	return int(data()["levels"]["xp_squad"])


static func xp_bench() -> int:
	return int(data()["levels"]["xp_bench"])


## Werte, die eine Stufe insgesamt gibt (kumulativ ab Stufe 2): Leben, Angriff, Verteidigung oder Magieresistenz (je nach Schadensart), Heilung.
static func bonus(level: int, unit_def: Dictionary) -> Dictionary:
	var b := {"hp": 0, "atk": 0, "def": 0, "res": 0, "heal": 0}
	var magic: bool = unit_def.get("dmg_type", "body") == "magic"
	var healer: bool = int(unit_def.get("heal", 0)) > 0
	if level >= 2:
		b["hp"] += 3
	if level >= 3:
		b["atk"] += 1
		if healer:
			b["heal"] += 1
	if level >= 4:
		b["hp"] += 3
		b["res" if magic else "def"] += 1
	if level >= 5:
		b["atk"] += 1
		b["hp"] += 3
		if healer:
			b["heal"] += 1
	return b


## Stufenbonus auf eine Kampffigur anwenden (einmal beim Aufstellen, vor der Ausruestung).
static func apply_level(u: Dictionary, level: int, unit_def: Dictionary) -> void:
	if level <= 1:
		return
	var b := bonus(level, unit_def)
	u["maxhp"] += int(b["hp"])
	u["hp"] += int(b["hp"])
	u["atk"] += int(b["atk"])
	u["def"] += int(b["def"])
	u["res"] = int(u.get("res", 0)) + int(b["res"])
	u["heal"] = int(u.get("heal", 0)) + int(b["heal"])


## Kurztext der Stufenboni fuer die Anzeige ("+3 Leben, +1 Angriff").
static func bonus_text(level: int, unit_def: Dictionary) -> String:
	var b := bonus(level, unit_def)
	var parts: PackedStringArray = []
	for k: String in ["hp", "atk", "def", "res", "heal"]:
		if int(b[k]) > 0:
			parts.append("+%d %s" % [int(b[k]), {"hp": "Leben", "atk": "Angriff", "def": "Verteidigung", "res": "Magieresistenz", "heal": "Heilung"}[k]])
	return ", ".join(parts)


## Gegnerfaktoren dieser Mission {hp, atk} (1.0 = unveraendert, auch fuer unbekannte Missionen).
static func enemy_scale(mission_id: String) -> Dictionary:
	var m: Dictionary = (data()["missions"] as Dictionary).get(mission_id, {})
	return {"hp": float(m.get("enemy_hp", 1.0)), "atk": float(m.get("enemy_atk", 1.0))}
