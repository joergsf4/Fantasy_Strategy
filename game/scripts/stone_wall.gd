class_name StoneWall
extends RefCounted
## Fantasy-Mauer aus unregelmaessigen Feldsteinen in versetzten Lagen, mit bemoosten Kanten, Efeuranken, Buschwerk und
## Blumen am Fuss. Das Aussehen haengt nur von der Kachelposition ab (jede Stelle der Mauer sieht anders aus).
## Lokale Achsen: lang entlang z (Laenge 1,0), dick entlang x (0,5), hoch y.

const STONE := [Color(0.56, 0.54, 0.5), Color(0.47, 0.46, 0.44), Color(0.62, 0.58, 0.52), Color(0.5, 0.47, 0.42),
	Color(0.43, 0.43, 0.45), Color(0.58, 0.55, 0.55)]
const GREEN := [Color(0.2, 0.42, 0.13), Color(0.3, 0.55, 0.2), Color(0.16, 0.36, 0.13), Color(0.42, 0.62, 0.24)]
const FLOWER := [Color(1, 1, 1), Color(1, 0.88, 0.3), Color(0.95, 0.5, 0.65), Color(0.7, 0.55, 0.95)]


static func _rng(pos: Vector2i, salt := 0) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = (pos.x * 73856093) ^ (pos.y * 19349663) ^ (salt * 83492791)
	return r


static func _noise(r: RandomNumberGenerator) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = r.randi()
	n.frequency = 1.4
	return n


static func _stone(k: MeshKit, r: RandomNumberGenerator, nz: FastNoiseLite, c: Vector3, rad: Vector3) -> void:
	var col: Color = STONE[r.randi() % STONE.size()]
	k.blob(c, rad, col.darkened(0.22), col.lightened(0.06), 0.2, nz, 1, false)


static func _green(k: MeshKit, r: RandomNumberGenerator, nz: FastNoiseLite, c: Vector3, rad: Vector3) -> void:
	var col: Color = GREEN[r.randi() % GREEN.size()]
	k.blob(c, rad, col.darkened(0.2), col.lightened(0.1), 0.3, nz, 1, true)


static func _flowers(k: MeshKit, r: RandomNumberGenerator, c: Vector3, n: int, spread: Vector3) -> void:
	for i in n:
		var p := c + Vector3(r.randf_range(-1, 1) * spread.x, r.randf_range(0, 1) * spread.y, r.randf_range(-1, 1) * spread.z)
		k.box(p, Vector3(0.04, 0.04, 0.04), FLOWER[r.randi() % FLOWER.size()], r.randf() * 3.0)


## Eine Efeuranke an einer Mauerseite (side = -1 oder +1): Stiel mit Blaettern.
static func _vine(k: MeshKit, r: RandomNumberGenerator, nz: FastNoiseLite, side: float, z0: float, top: float, length: float) -> void:
	k.box(Vector3(side * 0.255, top - length * 0.5, z0), Vector3(0.025, length, 0.03), Color(0.14, 0.3, 0.1))
	var n := int(length / 0.085)
	for i in n:
		var y := top - i * 0.085
		var z := z0 + (0.035 if i % 2 == 0 else -0.035)
		_green(k, r, nz, Vector3(side * 0.262, y, z), Vector3(0.03, 0.045, 0.05))


static func wall(k: MeshKit, pos: Vector2i) -> void:
	var r := _rng(pos)
	var nz := _noise(r)
	var hs := r.randf_range(0.95, 1.1)
	k.box(Vector3(0, 0.48 * hs, 0), Vector3(0.36, 0.96 * hs, 0.96), Color(0.3, 0.3, 0.32))   # Kern, damit keine Luecken durchscheinen
	for row in 6:
		var y := (0.1 + row * 0.17) * hs
		var zs: Array = [-0.34, 0.0, 0.34] if row % 2 == 0 else [-0.47, -0.17, 0.17, 0.47]
		for z: float in zs:
			var rz := r.randf_range(0.17, 0.2) if absf(z) < 0.45 else 0.1
			_stone(k, r, nz, Vector3(r.randf_range(-0.02, 0.02), y + r.randf_range(-0.015, 0.015), z + r.randf_range(-0.03, 0.03)),
				Vector3(r.randf_range(0.24, 0.27), r.randf_range(0.095, 0.125) * hs, rz))
	for i in 4:   # unregelmaessiger oberer Rand (Zinnen aus Steinen, mit Luecken)
		if r.randf() < 0.2:
			continue
		_stone(k, r, nz, Vector3(r.randf_range(-0.02, 0.02), 1.04 * hs + r.randf_range(-0.01, 0.03), -0.375 + i * 0.25),
			Vector3(0.2, r.randf_range(0.07, 0.1), 0.11))
	for z: float in [-0.3, 0.0, 0.3]:   # Moos auf der Krone
		_green(k, r, nz, Vector3(r.randf_range(-0.05, 0.05), 0.96 * hs, z + r.randf_range(-0.04, 0.04)), Vector3(0.24, 0.045, 0.17))
	_flowers(k, r, Vector3(0, 1.0 * hs, 0), 2, Vector3(0.1, 0.02, 0.4))
	for side: float in [-1.0, 1.0]:
		for p in r.randi_range(3, 5):   # Moospolster an den Seiten
			_green(k, r, nz, Vector3(side * 0.245, r.randf_range(0.12, 0.9) * hs, r.randf_range(-0.4, 0.4)),
				Vector3(0.05, r.randf_range(0.06, 0.12), r.randf_range(0.08, 0.16)))
		for v in r.randi_range(1, 2):
			_vine(k, r, nz, side, r.randf_range(-0.38, 0.38), r.randf_range(0.7, 1.0) * hs, r.randf_range(0.35, 0.75))
		for b in r.randi_range(1, 2):   # Buesche am Fuss
			var bz := r.randf_range(-0.35, 0.35)
			_green(k, r, nz, Vector3(side * 0.33, 0.08, bz), Vector3(0.14, r.randf_range(0.09, 0.13), r.randf_range(0.13, 0.2)))
			_flowers(k, r, Vector3(side * 0.33, 0.14, bz), 3, Vector3(0.08, 0.06, 0.12))


## Torpfeiler (z = -0.4 und +0.4): gestapelte Feldsteine mit Moos und Efeu.
static func gate_pillars(k: MeshKit, pos: Vector2i) -> void:
	var r := _rng(pos, 7)
	var nz := _noise(r)
	for z: float in [-0.4, 0.4]:
		k.box(Vector3(0, 0.58, z), Vector3(0.34, 1.16, 0.2), Color(0.3, 0.3, 0.32))
		for row in 7:
			_stone(k, r, nz, Vector3(r.randf_range(-0.02, 0.02), 0.1 + row * 0.165, z + r.randf_range(-0.02, 0.02)),
				Vector3(r.randf_range(0.26, 0.29), r.randf_range(0.09, 0.115), r.randf_range(0.19, 0.22)))
		_stone(k, r, nz, Vector3(0, 1.17, z), Vector3(0.3, 0.07, 0.23))
		_green(k, r, nz, Vector3(0, 1.24, z), Vector3(0.22, 0.04, 0.16))
		for side: float in [-1.0, 1.0]:
			_vine(k, r, nz, side, z + r.randf_range(-0.05, 0.05), r.randf_range(0.8, 1.1), r.randf_range(0.4, 0.7))
			_green(k, r, nz, Vector3(side * 0.3, 0.08, z + r.randf_range(-0.1, 0.1)), Vector3(0.12, 0.1, 0.14))
		_flowers(k, r, Vector3(0, 1.25, z), 2, Vector3(0.1, 0.02, 0.1))
	for i in 3:   # Steinreihe ueber dem Holzbalken
		_stone(k, r, nz, Vector3(0, 0.92, -0.22 + i * 0.22), Vector3(0.25, 0.09, 0.13))


## Trümmer nach dem Sprengen: zerbrochene Steine, Moos, Buesche und Blumen.
static func rubble(k: MeshKit, pos: Vector2i) -> void:
	var r := _rng(pos, 3)
	var nz := _noise(r)
	for i in 7:
		_stone(k, r, nz, Vector3(r.randf_range(-0.22, 0.22), 0.06, r.randf_range(-0.42, 0.42)),
			Vector3(r.randf_range(0.09, 0.16), r.randf_range(0.06, 0.1), r.randf_range(0.09, 0.15)))
	for i in 3:
		_green(k, r, nz, Vector3(r.randf_range(-0.2, 0.2), 0.1, r.randf_range(-0.4, 0.4)), Vector3(0.1, 0.05, 0.12))
	_flowers(k, r, Vector3(0, 0.12, 0), 3, Vector3(0.18, 0.04, 0.38))
