class_name Combat
extends RefCounted
## Reine Kampfregeln ohne 3D und ohne Szene (testbar): Werte mit Status, Positionsboni, Schaden, Gegenschlag.

const BACK_BONUS := 0.30
const FLANK_BONUS := 0.15
const HEIGHT_BONUS := 0.15
const HEIGHT_DIFF := 0.35
const AMBUSH_BONUS := 0.30
const DEFEND_FACTOR := 0.5         # Verteidigen: erlittener Schaden x0,5 (aufgerundet, mindestens 1)
const DEFEND_FACTOR_TANK := 0.4    # Tanks halten besser


## Wert inkl. Buffs/Debuffs aus Status (u["status"][i]["mods"][key]).
static func stat(u: Dictionary, key: String) -> int:
	var v: int = u.get(key, 0)
	for s: Dictionary in u.get("status", []):
		v += int(s.get("mods", {}).get(key, 0))
	return v


static func in_range(u: Dictionary, dist: int) -> bool:
	return dist >= u.get("range_min", 1) and dist <= u.get("range", 1)


## Bonus durch Position: Ruecken/Flanke (Blickrichtung des Verteidigers), Hoehe, Hinterhalt.
## Rueckgabe {"bonus": float, "tags": Array[String]}
static func position_bonus(att_pos: Vector2i, def_pos: Vector2i, def_dir: Vector2i, att_h: float, def_h: float, ambush := false) -> Dictionary:
	var bonus := 0.0
	var tags: Array[String] = []
	var rel := Vector2(att_pos - def_pos)
	if rel != Vector2.ZERO and def_dir != Vector2i.ZERO:
		var dot := rel.normalized().dot(Vector2(def_dir).normalized())
		if dot < -0.5:
			bonus += BACK_BONUS
			tags.append("Rücken +30 %")
		elif dot <= 0.5:
			bonus += FLANK_BONUS
			tags.append("Flanke +15 %")
	if att_h - def_h >= HEIGHT_DIFF:
		bonus += HEIGHT_BONUS
		tags.append("Höhe +15 %")
	if ambush:
		bonus += AMBUSH_BONUS
		tags.append("Hinterhalt +30 %")
	return {"bonus": bonus, "tags": tags}


## Schaden eines Treffers. mult = Faehigkeitsfaktor, ignore_def = Anteil der Verteidigung, der ignoriert wird.
static func damage(att: Dictionary, def: Dictionary, cover: int, pos_bonus: float, mult := 1.0, ignore_def := 0.0, flat := 0) -> int:
	var defense := stat(def, "res" if att.get("dmg_type", "body") == "magic" else "def")
	var raw := roundi(float(stat(att, "atk") + flat) * mult * (1.0 + pos_bonus))
	var dmg := maxi(1, raw - roundi(float(defense) * (1.0 - ignore_def)) - cover)
	if Status.has(def, "defend"):
		dmg = maxi(1, ceili(float(dmg) * defend_factor(def)))
	return dmg


static func defend_factor(u: Dictionary) -> float:
	return DEFEND_FACTOR_TANK if u.get("role", "") == "tank" else DEFEND_FACTOR


## Faktor fuer Angriffe auf Distanz (z. B. Wurfsterne der Ninjas).
static func range_mult(att: Dictionary, dist: int) -> float:
	return float(att.get("ranged_mult", 1.0)) if dist > 1 else 1.0


## Kontert der Verteidiger einen Angriff aus Entfernung dist?
static func can_counter(def: Dictionary, dist: int) -> bool:
	if def.get("hp", 0) <= 0 or Status.has(def, "stun") or Status.has(def, "defend"):
		return false   # Betaeubte und Verteidigende kontern nicht
	return in_range(def, dist)
