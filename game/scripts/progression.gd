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
