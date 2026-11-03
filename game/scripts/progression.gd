class_name Progression
extends RefCounted
## Fortschritt ueber die Kapitel: Daten der Zielkurve (data/progression.json), Gegnerfaktoren je Mission und Talentpunkte-Einstellungen (siehe Talents).
## Reine Regeln ohne Szene: gemeinsam genutzt von Battle (Spiel), Talents und SimBattle (Balancing).

static var _d: Dictionary = {}


static func data() -> Dictionary:
	if _d.is_empty():
		_d = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression.json"))
	return _d


## Gegnerfaktoren dieser Mission {hp, atk} (1.0 = unveraendert, auch fuer unbekannte Missionen).
static func enemy_scale(mission_id: String) -> Dictionary:
	var m: Dictionary = (data()["missions"] as Dictionary).get(mission_id, {})
	return {"hp": float(m.get("enemy_hp", 1.0)), "atk": float(m.get("enemy_atk", 1.0))}


## Ausruestung fuer einen Helden bei durchschnittlicher Stufe tier (z. B. 2,5): Waffe aufgerundet, Ruestung und Talisman abgerundet; je Platz das beste Stueck
## bis zu dieser Stufe, das er tragen darf (Testlabor, START_CH und Balancing).
static func gear_for(unit_def: Dictionary, tier: float) -> Array:
	var caps := {"waffe": ceili(tier), "ruestung": maxi(1, floori(tier)), "talisman": maxi(1, floori(tier))}
	var magic: bool = unit_def.get("dmg_type", "body") == "magic"
	var best := {}
	for id: String in Items.equipment():
		var it: Dictionary = Items.equipment()[id]
		if int(it["tier"]) > int(caps[it["slot"]]) or not Items.can_equip({"dmg_type": unit_def.get("dmg_type", "body"), "range": int(unit_def["range"])}, id):
			continue
		var has_res: bool = (it["mods"] as Dictionary).has("res")
		if it["slot"] == "ruestung" and (magic != has_res):
			continue
		var score := int(it["tier"]) * 1000
		for k: String in it["mods"]:
			score += absi(int(it["mods"][k]))
		if not best.has(it["slot"]) or score > int(best[it["slot"]][0]):
			best[it["slot"]] = [score, id]
	var out: Array = []
	for slot: String in best:
		out.append(best[slot][1])
	return out


## Anzahl geschaffter Kampfmissionen vor Kapitel n (Mission 10 ist ein Zwischenspiel ohne Kampf).
static func missions_done_before(n: int) -> int:
	return n - 1 if n <= 10 else n - 2
