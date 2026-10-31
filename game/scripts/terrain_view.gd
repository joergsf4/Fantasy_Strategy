class_name TerrainView
extends Node3D
## Natuerliche 3D-Landschaft unter dem logischen Raster: Huegel, Seen, Gras, Baeume, Dorf, Burg.
## Spiellogik bleibt auf Kacheln (Grid); hier steckt nur Optik und die Hoehenabfrage.

const MARGIN := 9            # Umland rund um das Spielfeld (Kacheln)
const RES := 5               # Gitterpunkte pro Kachel im Bodenmesh
const WATER_LEVEL := -0.08

# Zielhoehe und Rauigkeit je Gelaendetyp (an den Kachelmitten, dazwischen weich interpoliert)
const H := {"G": 0.0, "F": 0.03, "M": 1.0, "W": -0.5, "V": 0.02, "C": 0.05, "P": 0.0}
const AMP := {"G": 0.035, "F": 0.05, "M": 0.3, "W": 0.04, "V": 0.0, "C": 0.0, "P": 0.0}
# Bodengewichte: R Gras, G Waldboden, B Fels, A Pfad
const WT := {
	"G": Color(1, 0, 0, 0), "F": Color(0.35, 0.65, 0, 0), "M": Color(0.1, 0, 0.9, 0),
	"W": Color(1, 0, 0, 0), "V": Color(0.7, 0, 0, 0.6), "C": Color(0, 0, 0.7, 0.3), "P": Color(1, 0, 0, 0),
}

var grid: Grid
var _noise := FastNoiseLite.new()
var _noise_hills := FastNoiseLite.new()
var _noise_forest := FastNoiseLite.new()
var _noise_warp := FastNoiseLite.new()
var _blob_noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _mesh_cache := {}
var _foliage_mat: ShaderMaterial
var _grass_mat: ShaderMaterial

# Baumvarianten (Mesh) und gesammelte Instanzen
var _meshes := {}
var _inst := {}   # name -> {"xf": Array[Transform3D], "col": PackedColorArray}


func setup(g: Grid) -> void:
	grid = g
	_rng.seed = 20260
	_noise.seed = 3
	_noise.frequency = 0.45
	_noise.fractal_octaves = 3
	_noise_hills.seed = 11
	_noise_hills.frequency = 0.16
	_noise_hills.fractal_octaves = 3
	_noise_warp.seed = 21
	_noise_warp.frequency = 0.9
	_noise_warp.fractal_octaves = 2
	_noise_forest.seed = 5
	_noise_forest.frequency = 0.35
	_blob_noise.seed = 9
	_blob_noise.frequency = 1.3
	_foliage_mat = ShaderMaterial.new()
	_foliage_mat.shader = load("res://shaders/foliage.gdshader")
	_grass_mat = ShaderMaterial.new()
	_grass_mat.shader = load("res://shaders/grass.gdshader")
	_make_meshes()
	_build_ground()
	_build_water()
	_scatter()
	_build_structures()
	_flush_instances()


# ---------------------------------------------------------------- Hoehenfeld

func _tt(i: int, j: int) -> String:
	return grid.terrain(Vector2i(clampi(i, 0, grid.width - 1), clampi(j, 0, grid.height - 1)))


func _corners(x: float, z: float) -> Array:
	var wx := x + _noise_warp.get_noise_2d(x, z) * 0.55
	var wz := z + _noise_warp.get_noise_2d(x + 31.0, z - 17.0) * 0.55
	x = wx
	z = wz
	var fx := floorf(x)
	var fz := floorf(z)
	return [int(fx), int(fz), smoothstep(0.0, 1.0, x - fx), smoothstep(0.0, 1.0, z - fz)]


func _sample_f(x: float, z: float, table: Dictionary) -> float:
	var c := _corners(x, z)
	var i: int = c[0]
	var j: int = c[1]
	var a: float = table[_tt(i, j)]
	var b: float = table[_tt(i + 1, j)]
	var cc: float = table[_tt(i, j + 1)]
	var d: float = table[_tt(i + 1, j + 1)]
	return lerpf(lerpf(a, b, c[2]), lerpf(cc, d, c[2]), c[3])


func _sample_c(x: float, z: float) -> Color:
	var c := _corners(x, z)
	var i: int = c[0]
	var j: int = c[1]
	var a: Color = WT[_tt(i, j)]
	var b: Color = WT[_tt(i + 1, j)]
	var cc: Color = WT[_tt(i, j + 1)]
	var d: Color = WT[_tt(i + 1, j + 1)]
	return a.lerp(b, c[2]).lerp(cc.lerp(d, c[2]), c[3])


func dist_outside(x: float, z: float) -> float:
	var dx := maxf(maxf(-x, x - (grid.width - 1)), 0.0)
	var dz := maxf(maxf(-z, z - (grid.height - 1)), 0.0)
	return sqrt(dx * dx + dz * dz)


func height_at(x: float, z: float) -> float:
	var h := _sample_f(x, z, H) + _noise.get_noise_2d(x, z) * _sample_f(x, z, AMP)
	var d := dist_outside(x, z)
	if d > 0.0:
		var n01 := _noise_hills.get_noise_2d(x, z) * 0.5 + 0.5
		h += smoothstep(0.4, 6.0, d) * (0.25 + 1.2 * n01)
		h += _noise.get_noise_2d(x + 40.0, z) * 0.05 * smoothstep(0.0, 2.0, d)
	return h


## Hoehe, auf der eine Figur auf dieser Kachel steht (Wasser: Wasseroberflaeche).
func tile_height(p: Vector2i) -> float:
	return maxf(height_at(p.x, p.y), WATER_LEVEL)


func _normal_at(x: float, z: float) -> Vector3:
	var e := 0.05
	return Vector3(height_at(x - e, z) - height_at(x + e, z), 2.0 * e, height_at(x, z - e) - height_at(x, z + e)).normalized()


## Strahl gegen das Gelaende -> getroffene Kachel (Marsch + Bisektion).
func pick(o: Vector3, d: Vector3) -> Vector2i:
	if d.y > -0.0001:
		return Vector2i(-1, -1)
	var t := maxf(0.0, (1.2 - o.y) / d.y)
	var prev := t
	for i in 600:
		var p := o + d * t
		if p.y <= maxf(height_at(p.x, p.z), WATER_LEVEL):
			var lo := prev
			var hi := t
			for k in 12:
				var mid := (lo + hi) * 0.5
				var q := o + d * mid
				if q.y <= maxf(height_at(q.x, q.z), WATER_LEVEL):
					hi = mid
				else:
					lo = mid
			var r := o + d * hi
			return Vector2i(roundi(r.x), roundi(r.z))
		prev = t
		t += 0.08
	return Vector2i(-1, -1)


## Flaches Netz, das dem Gelaende folgt (Markierungen, Cursor).
func tile_mesh(p: Vector2i, half := 0.46, lift := 0.035) -> ArrayMesh:
	var key := [p, half, lift]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var n := 6
	var verts := PackedVector3Array()
	for j in n + 1:
		for i in n + 1:
			var x := p.x - half + 2.0 * half * i / n
			var z := p.y - half + 2.0 * half * j / n
			verts.append(Vector3(x, maxf(height_at(x, z), WATER_LEVEL) + lift, z))
	var idx := PackedInt32Array()
	for j in n:
		for i in n:
			var a := j * (n + 1) + i
			var b := a + 1
			var c := a + n + 1
			var d := c + 1
			idx.append_array([a, b, d, a, d, c])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_mesh_cache[key] = m
	return m


# ---------------------------------------------------------------- Boden und Wasser

func _grid_dims() -> Vector4:
	var x0 := -MARGIN - 0.5
	return Vector4(x0, x0, (grid.width + 2 * MARGIN) * RES, (grid.height + 2 * MARGIN) * RES)


func _build_ground() -> void:
	var dm := _grid_dims()
	var nx := int(dm.z)
	var nz := int(dm.w)
	var step := 1.0 / RES
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	for j in nz + 1:
		for i in nx + 1:
			var x := dm.x + i * step
			var z := dm.y + j * step
			verts.append(Vector3(x, height_at(x, z), z))
			norms.append(_normal_at(x, z))
			cols.append(_sample_c(x, z))
	var idx := PackedInt32Array()
	for j in nz:
		for i in nx:
			var a := j * (nx + 1) + i
			var b := a + 1
			var c := a + nx + 1
			var d := c + 1
			idx.append_array([a, b, d, a, d, c])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ground.gdshader")
	mat.set_shader_parameter("water_level", WATER_LEVEL)
	mat.set_shader_parameter("map_rect", Vector4(-0.5, -0.5, grid.width - 0.5, grid.height - 0.5))
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.name = "Ground"
	add_child(mi)


func _build_water() -> void:
	var dm := _grid_dims()
	var nx := int(dm.z)
	var nz := int(dm.w)
	var step := 1.0 / RES
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	var depth := PackedFloat32Array()
	for j in nz + 1:
		for i in nx + 1:
			var x := dm.x + i * step
			var z := dm.y + j * step
			var d := WATER_LEVEL - height_at(x, z)
			depth.append(d)
			verts.append(Vector3(x, WATER_LEVEL, z))
			cols.append(Color(d, 0, 0, 1))
	var idx := PackedInt32Array()
	for j in nz:
		for i in nx:
			var a := j * (nx + 1) + i
			var b := a + 1
			var c := a + nx + 1
			var d := c + 1
			if maxf(maxf(depth[a], depth[b]), maxf(depth[c], depth[d])) < 0.0:
				continue
			idx.append_array([a, b, d, a, d, c])
	if idx.is_empty():
		return
	var norms := PackedVector3Array()
	norms.resize(verts.size())
	norms.fill(Vector3.UP)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/water.gdshader")
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.name = "Water"
	add_child(mi)


# ---------------------------------------------------------------- Meshes fuer Pflanzen & Felsen

func _make_meshes() -> void:
	var bark := Color(0.30, 0.20, 0.12)
	# Kiefern (2 Varianten)
	for v in 2:
		var k := MeshKit.new()
		var s := 1.0 + 0.12 * v
		k.frustum(Vector3.ZERO, 0.035, 0.025, 0.28, bark, bark, 6)
		var dark := Color(0.10, 0.28, 0.14)
		var lite := Color(0.22, 0.46, 0.20)
		k.frustum(Vector3(0, 0.16, 0), 0.27 * s, 0.0, 0.40, dark, lite, 9)
		k.frustum(Vector3(0, 0.38, 0), 0.21 * s, 0.0, 0.36, dark, lite, 9)
		k.frustum(Vector3(0, 0.58 + 0.04 * v, 0), 0.14 * s, 0.0, 0.34, dark, lite, 9)
		_meshes["pine%d" % v] = k.build()
	# Laubbaeume (3 Varianten)
	for v in 3:
		var k := MeshKit.new()
		var th := 0.34 + 0.06 * v
		k.frustum(Vector3.ZERO, 0.055, 0.035, th, bark, bark.lightened(0.1), 7)
		var dark := Color(0.17, 0.36, 0.12)
		var lite := Color(0.40, 0.62, 0.20)
		_blob_noise.seed = 100 + v
		k.blob(Vector3(0, th + 0.12, 0), Vector3(0.27, 0.22, 0.27) * (1.0 + 0.1 * v), dark, lite, 0.28, _blob_noise)
		k.blob(Vector3(0.14, th + 0.04, 0.05), Vector3(0.19, 0.16, 0.19), dark, lite, 0.28, _blob_noise)
		k.blob(Vector3(-0.13, th + 0.07, -0.06), Vector3(0.20, 0.17, 0.2), dark, lite, 0.28, _blob_noise)
		if v == 2:
			k.blob(Vector3(0.02, th + 0.28, -0.05), Vector3(0.16, 0.14, 0.16), dark, lite.lightened(0.1), 0.25, _blob_noise)
		_meshes["oak%d" % v] = k.build()
	# Busch, Felsen
	var kb := MeshKit.new()
	_blob_noise.seed = 77
	kb.blob(Vector3(0, 0.07, 0), Vector3(0.14, 0.1, 0.14), Color(0.14, 0.32, 0.12), Color(0.34, 0.56, 0.2), 0.3, _blob_noise, 1)
	kb.blob(Vector3(0.1, 0.05, 0.04), Vector3(0.09, 0.07, 0.09), Color(0.14, 0.32, 0.12), Color(0.34, 0.56, 0.2), 0.3, _blob_noise, 1)
	_meshes["bush"] = kb.build()
	for v in 2:
		var kr := MeshKit.new()
		_blob_noise.seed = 200 + v
		kr.blob(Vector3(0, 0.07, 0), Vector3(0.2, 0.13, 0.17), Color(0.26, 0.24, 0.22), Color(0.50, 0.48, 0.44), 0.35, _blob_noise, 1, false)
		_meshes["rock%d" % v] = kr.build()
	# Grasbueschel: mehrere dreieckige Halme
	var kg := MeshKit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for b in 6:
		var ang := rng.randf() * TAU
		var off := Vector3(cos(ang), 0, sin(ang)) * rng.randf_range(0.0, 0.035)
		var hgt := rng.randf_range(0.11, 0.2)
		var lean := Vector3(rng.randf_range(-0.05, 0.05), 0, rng.randf_range(-0.05, 0.05))
		var side := Vector3(cos(ang + PI * 0.5), 0, sin(ang + PI * 0.5)) * 0.012
		var base_c := Color(0.36, 0.56, 0.20)
		var tip_c := Color(0.60, 0.80, 0.30)
		var a := kg._v(off - side, Vector3.UP, base_c)
		var bb := kg._v(off + side, Vector3.UP, base_c)
		var t := kg._v(off + lean + Vector3(0, hgt, 0), Vector3.UP, tip_c)
		kg.idx.append_array([a, bb, t])
		kg.idx.append_array([a, t, bb])
	_meshes["grass"] = kg.build()
	# Blume: Stiel + kleiner Kopf (Alpha 1 = Kopf, nimmt Instanzfarbe)
	var kf := MeshKit.new()
	var stem := Color(0.2, 0.4, 0.12, 0.0)
	var head := Color(1, 1, 1, 1)
	var s0 := kf._v(Vector3(-0.006, 0, 0), Vector3.UP, stem)
	var s1 := kf._v(Vector3(0.006, 0, 0), Vector3.UP, stem)
	var s2 := kf._v(Vector3(0, 0.1, 0), Vector3.UP, stem)
	kf.idx.append_array([s0, s1, s2, s0, s2, s1])
	var hc := Vector3(0, 0.105, 0)
	var hp := [Vector3(-0.03, 0, 0), Vector3(0, 0, 0.03), Vector3(0.03, 0, 0), Vector3(0, 0, -0.03)]
	var hcv := kf._v(hc + Vector3(0, 0.012, 0), Vector3.UP, head)
	var hv := []
	for p: Vector3 in hp:
		hv.append(kf._v(hc + p, Vector3.UP, head))
	for i in 4:
		kf.idx.append_array([hcv, hv[i], hv[(i + 1) % 4]])
		kf.idx.append_array([hcv, hv[(i + 1) % 4], hv[i]])
	_meshes["flower"] = kf.build()


func _add(kind: String, pos: Vector3, scale: float, tint: Color, yaw := -1.0) -> void:
	if not _inst.has(kind):
		_inst[kind] = {"xf": [], "col": PackedColorArray()}
	var y := yaw if yaw >= 0.0 else _rng.randf() * TAU
	var b := Basis(Vector3.UP, y).scaled(Vector3(scale, scale * _rng.randf_range(0.9, 1.15), scale))
	_inst[kind]["xf"].append(Transform3D(b, pos))
	_inst[kind]["col"].append(tint)


func _tint(spread := 0.12) -> Color:
	return Color(1.0 + _rng.randf_range(-spread, spread), 1.0 + _rng.randf_range(-spread * 0.6, spread * 0.6), 1.0 + _rng.randf_range(-spread, spread))


func _place(kind: String, x: float, z: float, scale: float, tint: Color, min_y := WATER_LEVEL + 0.04) -> bool:
	var y := height_at(x, z)
	if y < min_y:
		return false
	_add(kind, Vector3(x, y - 0.015, z), scale, tint)
	return true


func _tree(x: float, z: float, scale: float, prefer_pine := 0.45) -> void:
	var kind := ("pine%d" % _rng.randi_range(0, 1)) if _rng.randf() < prefer_pine else ("oak%d" % _rng.randi_range(0, 2))
	_place(kind, x, z, scale * 0.72 * _rng.randf_range(0.85, 1.25), _tint(0.14))


func _scatter() -> void:
	for tj in range(-MARGIN, grid.height + MARGIN):
		for ti in range(-MARGIN, grid.width + MARGIN):
			var inside := ti >= 0 and tj >= 0 and ti < grid.width and tj < grid.height
			var t := _tt(ti, tj)
			var d := dist_outside(ti, tj)
			if inside:
				_scatter_tile(ti, tj, t)
			else:
				_scatter_outer(ti, tj, t, d)


func _jit(c: float, r := 0.45) -> float:
	return c + _rng.randf_range(-r, r)


func _grass(ti: int, tj: int, count: int, min_y := WATER_LEVEL + 0.05) -> void:
	for i in count:
		var x := _jit(ti)
		var z := _jit(tj)
		var dry := _noise_hills.get_noise_2d(x * 2.0, z * 2.0) * 0.5 + 0.5
		var tint := Color(0.8 + 0.5 * dry + _rng.randf_range(-0.1, 0.1), 0.95 + _rng.randf_range(-0.12, 0.12), 0.7 + _rng.randf_range(-0.1, 0.1))
		_place("grass", x, z, _rng.randf_range(0.8, 1.35), tint, min_y)


func _flowers(ti: int, tj: int, count: int) -> void:
	var pal := [Color(1, 1, 1), Color(1, 0.9, 0.25), Color(0.95, 0.45, 0.6), Color(0.65, 0.5, 0.95), Color(1, 0.6, 0.2)]
	for i in count:
		_place("flower", _jit(ti), _jit(tj), _rng.randf_range(0.8, 1.2), pal[_rng.randi() % pal.size()])


func _scatter_tile(ti: int, tj: int, t: String) -> void:
	if grid.blocked.has(Vector2i(ti, tj)):   # Mauer/Tor: kein Buschwerk, das durchragt
		_grass(ti, tj, 4)
		return
	match t:
		"G":
			_grass(ti, tj, 10)
			if _rng.randf() < 0.55:
				_flowers(ti, tj, _rng.randi_range(1, 4))
			var corner := Vector2(_rng.randf_range(0.3, 0.45) * (1 if _rng.randf() < 0.5 else -1), _rng.randf_range(0.3, 0.45) * (1 if _rng.randf() < 0.5 else -1))
			var roll := _rng.randf()
			if roll < 0.07:
				_tree(ti + corner.x, tj + corner.y, 0.9)
			elif roll < 0.22:
				_place("bush", ti + corner.x, tj + corner.y, _rng.randf_range(0.8, 1.2), _tint(0.1))
			elif roll < 0.28:
				_place("rock%d" % _rng.randi_range(0, 1), ti + corner.x, tj + corner.y, _rng.randf_range(0.5, 0.9), _tint(0.1))
		"F":
			_grass(ti, tj, 4)
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					if _rng.randf() < 0.88:
						_tree(ti + sx * _rng.randf_range(0.22, 0.4), tj + sz * _rng.randf_range(0.22, 0.4), 1.0)
			if _rng.randf() < 0.6:
				_place("bush", _jit(ti, 0.3), _jit(tj, 0.3), 0.9, _tint(0.1))
		"M":
			_grass(ti, tj, 3, 0.1)
			for i in _rng.randi_range(3, 5):
				_place("rock%d" % _rng.randi_range(0, 1), _jit(ti, 0.4), _jit(tj, 0.4), _rng.randf_range(0.7, 1.5), _tint(0.12))
			if _rng.randf() < 0.7:
				_place("pine%d" % _rng.randi_range(0, 1), _jit(ti, 0.4), _jit(tj, 0.4), 0.85, _tint(0.12), 0.0)
		"W":
			for i in _rng.randi_range(0, 2):
				var x := _jit(ti, 0.5)
				var z := _jit(tj, 0.5)
				var y := height_at(x, z)
				if y > WATER_LEVEL - 0.12 and y < WATER_LEVEL + 0.1:
					_place("rock%d" % _rng.randi_range(0, 1), x, z, _rng.randf_range(0.35, 0.6), _tint(0.1), -1.0)
		"V":
			_grass(ti, tj, 6)
			_flowers(ti, tj, 2)
		"C":
			_grass(ti, tj, 3)


func _scatter_outer(ti: int, tj: int, t: String, d: float) -> void:
	var h := height_at(ti, tj)
	if h < WATER_LEVEL + 0.03:
		return
	_grass(ti, tj, 7 if d < 4.0 else 4)
	if _rng.randf() < 0.35:
		_flowers(ti, tj, _rng.randi_range(1, 3))
	var f := _noise_forest.get_noise_2d(ti, tj)
	if d > 1.6 and f > 0.0:
		var n := 1 + int(f * 5.0)
		var pine_bias := clampf(h * 1.2, 0.2, 0.85)
		for i in n:
			_tree(_jit(ti, 0.5), _jit(tj, 0.5), 1.0 + 0.15 * h, pine_bias)
	elif d > 0.9 and _rng.randf() < 0.22:
		_place("bush", _jit(ti), _jit(tj), 1.0, _tint(0.1))
	if h > 0.55 or (d > 2.0 and _rng.randf() < 0.18):
		for i in _rng.randi_range(1, 3):
			_place("rock%d" % _rng.randi_range(0, 1), _jit(ti, 0.45), _jit(tj, 0.45), _rng.randf_range(0.7, 1.6), _tint(0.12))


func _flush_instances() -> void:
	for kind: String in _inst:
		var data: Dictionary = _inst[kind]
		var xf: Array = data["xf"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _meshes[kind]
		mm.instance_count = xf.size()
		for i in xf.size():
			mm.set_instance_transform(i, xf[i])
			mm.set_instance_color(i, data["col"][i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		var is_plant := kind == "grass" or kind == "flower"
		mmi.material_override = _grass_mat if is_plant else _foliage_mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if is_plant else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mmi.name = "Inst_" + kind
		add_child(mmi)


# ---------------------------------------------------------------- Dorf & Burg

func _build_structures() -> void:
	for j in grid.height:
		for i in grid.width:
			var t := grid.terrain(Vector2i(i, j))
			if t == "V":
				_village(i, j)
			elif t == "C":
				_castle(i, j)
			elif t == "P":
				_planks(i, j)


func _build_mesh_at(k: MeshKit, x: float, y: float, z: float, name: String) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = k.build()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mi.material_override = mat
	mi.position = Vector3(x, y, z)
	mi.name = name
	add_child(mi)


## Ein Fachwerkhaus: Steinsockel, Putz mit Balken, Tuer, Fenster, Giebeldach mit First, Schornstein.
func _house(k: MeshKit, c: Vector3, size: Vector3, rot: float, roof: Color, wall: Color, floors := 1) -> void:
	var timber := Color(0.36, 0.23, 0.13)
	var stone := Color(0.52, 0.5, 0.47)
	var bs := Basis(Vector3.UP, rot)
	var h := size.y * floors
	var P := func(x: float, y: float, z: float) -> Vector3:
		return c + bs * Vector3(x, y, z)
	k.box(P.call(0, 0.03, 0), Vector3(size.x * 1.06, 0.06, size.z * 1.06), stone, rot)           # Sockel
	k.box(P.call(0, 0.06 + h * 0.5, 0), Vector3(size.x, h, size.z), wall, rot)                   # Wand
	for sx in [-1, 1]:                                                                            # Eckbalken
		for sz in [-1, 1]:
			k.box(P.call(sx * size.x * 0.5, 0.06 + h * 0.5, sz * size.z * 0.5), Vector3(0.03, h + 0.02, 0.03), timber, rot)
	k.box(P.call(0, 0.06 + h * 0.5, size.z * 0.5 + 0.004), Vector3(size.x, 0.025, 0.012), timber, rot)   # Querbalken vorn
	if floors > 1:
		k.box(P.call(0, 0.06 + size.y, 0), Vector3(size.x * 1.03, 0.03, size.z * 1.03), timber, rot)     # Geschossbalken
	k.box(P.call(-size.x * 0.17, 0.06 + size.y * 0.42, size.z * 0.5 + 0.008), Vector3(size.x * 0.2, size.y * 0.68, 0.02), Color(0.28, 0.17, 0.09), rot)   # Tuer
	k.box(P.call(-size.x * 0.17, 0.06 + size.y * 0.78, size.z * 0.5 + 0.012), Vector3(size.x * 0.12, size.y * 0.1, 0.01), Color(0.95, 0.85, 0.4), rot)   # Tuerbeleuchtung
	for wx in [0.22, 0.38]:
		k.box(P.call(size.x * wx, 0.06 + size.y * 0.6, size.z * 0.5 + 0.008), Vector3(size.x * 0.13, size.y * 0.24, 0.02), Color(0.98, 0.84, 0.45), rot)   # Fenster
		k.box(P.call(size.x * wx, 0.06 + size.y * 0.6, size.z * 0.5 + 0.014), Vector3(size.x * 0.13 + 0.02, 0.012, 0.012), timber, rot)
	if floors > 1:
		for wx in [-0.25, 0.0, 0.25]:
			k.box(P.call(size.x * wx, 0.06 + size.y * 1.6, size.z * 0.5 + 0.008), Vector3(size.x * 0.13, size.y * 0.24, 0.02), Color(0.98, 0.84, 0.45), rot)
	var ridge := size.z * 0.38
	k.gable_roof(P.call(0, 0.06 + h, 0), Vector3(size.x * 1.22, 0, size.z * 1.2), ridge, roof, rot)
	k.box(P.call(0, 0.06 + h + ridge + 0.005, 0), Vector3(size.x * 1.24, 0.025, 0.04), roof.darkened(0.35), rot)   # First
	var ch := bs * Vector3(size.x * 0.28, 0, -size.z * 0.15)
	k.box(Vector3(c.x + ch.x, c.y + 0.06 + h + ridge * 0.6 + 0.07, c.z + ch.z), Vector3(0.06, 0.14, 0.06), stone.darkened(0.15), rot)   # Schornstein
	k.box(Vector3(c.x + ch.x, c.y + 0.06 + h + ridge * 0.6 + 0.15, c.z + ch.z), Vector3(0.08, 0.02, 0.08), stone.darkened(0.3), rot)


## Holzsteg: Bohlen quer zur Laufrichtung, Querbalken und Pfosten, die ins Wasser ragen.
func _planks(ti: int, tj: int) -> void:
	var k := MeshKit.new()
	var wood := Color(0.55, 0.38, 0.2)
	var dark := Color(0.34, 0.22, 0.12)
	var along_x: bool = grid.inside(Vector2i(ti + 1, tj)) and grid.terrain(Vector2i(ti + 1, tj)) == "P" or grid.inside(Vector2i(ti - 1, tj)) and grid.terrain(Vector2i(ti - 1, tj)) == "P"
	var y0 := 0.05
	for n in 7:
		var u := -0.42 + n * 0.14
		var tint := wood.lightened(0.06 * float(n % 2)) if n % 3 else wood.darkened(0.08)
		if along_x:
			k.box(Vector3(u, y0, 0), Vector3(0.12, 0.035, 0.96), tint)
		else:
			k.box(Vector3(0, y0, u), Vector3(0.96, 0.035, 0.12), tint)
	for s in [-1, 1]:
		if along_x:
			k.box(Vector3(0, y0 - 0.04, s * 0.34), Vector3(0.96, 0.04, 0.05), dark)
			for e in [-1, 1]:
				k.box(Vector3(e * 0.46, -0.15, s * 0.44), Vector3(0.06, 0.45, 0.06), dark)
		else:
			k.box(Vector3(s * 0.34, y0 - 0.04, 0), Vector3(0.05, 0.04, 0.96), dark)
			for e in [-1, 1]:
				k.box(Vector3(s * 0.44, -0.15, e * 0.46), Vector3(0.06, 0.45, 0.06), dark)
	_build_mesh_at(k, ti, height_at(ti, tj), tj, "Pier_%d_%d" % [ti, tj])


func _village(ti: int, tj: int) -> void:
	var k := MeshKit.new()
	var timber := Color(0.36, 0.23, 0.13)
	var plaster := [Color(0.9, 0.84, 0.68), Color(0.86, 0.78, 0.6), Color(0.92, 0.88, 0.76)]
	var roofs := [Color(0.62, 0.2, 0.14), Color(0.5, 0.28, 0.16), Color(0.7, 0.3, 0.18)]
	var houses := [
		[Vector3(-0.3, 0, -0.27), Vector3(0.28, 0.19, 0.22), 0.12, 2],
		[Vector3(0.3, 0, -0.22), Vector3(0.26, 0.17, 0.24), -0.2, 1],
		[Vector3(-0.28, 0, 0.22), Vector3(0.26, 0.16, 0.2), 0.05, 1],
		[Vector3(0.28, 0, 0.2), Vector3(0.2, 0.14, 0.2), 0.4, 1],
	]
	var i := 0
	for h in houses:
		var p: Vector3 = h[0]
		var gy := height_at(ti + p.x, tj + p.z) - height_at(ti, tj)
		_house(k, Vector3(p.x, gy, p.z), h[1], h[2], roofs[i % 3], plaster[i % 3], h[3])
		i += 1
	# Brunnen in der Mitte
	var wc := Vector3(0.0, height_at(ti, tj) - height_at(ti, tj), -0.02)
	k.frustum(wc, 0.075, 0.07, 0.1, Color(0.5, 0.48, 0.45), Color(0.62, 0.6, 0.56), 8, false)
	k.frustum(wc + Vector3(0, 0.1, 0), 0.055, 0.055, 0.005, Color(0.2, 0.4, 0.6), Color(0.2, 0.4, 0.6), 8, true)
	for sx in [-1, 1]:
		k.box(wc + Vector3(sx * 0.07, 0.17, 0), Vector3(0.015, 0.14, 0.015), timber)
	k.gable_roof(wc + Vector3(0, 0.24, 0), Vector3(0.2, 0, 0.14), 0.07, Color(0.55, 0.3, 0.18), PI / 2.0)
	# Zaun mit Pfosten und zwei Latten, an zwei Seiten
	for side in 2:
		for n in 7:
			var u := -0.46 + n * 0.153
			var fx := u if side == 0 else -0.47
			var fz := 0.47 if side == 0 else u
			var gy := height_at(ti + fx, tj + fz) - height_at(ti, tj)
			k.box(Vector3(fx, gy + 0.05, fz), Vector3(0.025, 0.1, 0.025), timber)
		var rail := Vector3(0.0 if side == 0 else -0.47, 0.0, 0.47 if side == 0 else 0.0)
		var rsize := Vector3(0.92, 0.014, 0.012) if side == 0 else Vector3(0.012, 0.014, 0.92)
		for ry in [0.04, 0.08]:
			k.box(rail + Vector3(0, height_at(ti + rail.x, tj + rail.z) - height_at(ti, tj) + ry, 0), rsize, timber.lightened(0.1))
	# Heuhaufen und Fass
	var hay := Vector3(0.42, height_at(ti + 0.42, tj + 0.46) - height_at(ti, tj), 0.46)
	k.frustum(hay, 0.07, 0.01, 0.1, Color(0.8, 0.68, 0.3), Color(0.92, 0.8, 0.4), 7)
	var bar := Vector3(-0.42, height_at(ti - 0.42, tj + 0.4) - height_at(ti, tj), 0.4)
	k.frustum(bar, 0.04, 0.04, 0.08, Color(0.45, 0.28, 0.14), Color(0.5, 0.32, 0.17), 8, true)
	_build_mesh_at(k, ti, height_at(ti, tj), tj, "Village_%d_%d" % [ti, tj])


## Eine Zinnenreihe entlang einer Mauer (Richtung dir = X oder Z).
func _crenel(k: MeshKit, from: Vector3, to: Vector3, y: float, col: Color, n: int) -> void:
	for i in n:
		var t := (float(i) + 0.5) / float(n)
		var p := from.lerp(to, t)
		k.box(Vector3(p.x, y, p.z), Vector3(0.07, 0.07, 0.07) if absf(to.x - from.x) > absf(to.z - from.z) else Vector3(0.07, 0.07, 0.07), col)


func _tower(k: MeshKit, c: Vector3, r: float, h: float, stone: Color, dark: Color, roof: Color) -> void:
	k.frustum(c, r * 1.12, r, h, stone.darkened(0.1), stone, 10, false)
	k.frustum(c + Vector3(0, h, 0), r * 1.22, r * 1.22, 0.05, dark, dark.lightened(0.1), 10, true)       # Kranz
	k.frustum(c + Vector3(0, h + 0.05, 0), r * 1.04, 0.0, h * 0.6, roof.darkened(0.1), roof.lightened(0.15), 10)   # Spitzdach
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:                                                         # Schiessscharten
		var d := Vector3(cos(a), 0, sin(a))
		k.box(c + d * (r * 0.98) + Vector3(0, h * 0.62, 0), Vector3(0.02 if absf(d.x) > 0.5 else 0.045, 0.1, 0.045 if absf(d.x) > 0.5 else 0.02), Color(0.06, 0.05, 0.08))
	for n in 8:                                                                                      # Zinnen am Kranz
		var a2 := TAU * n / 8.0
		k.box(c + Vector3(cos(a2) * r * 1.2, h + 0.085, sin(a2) * r * 1.2), Vector3(0.05, 0.05, 0.05), dark, a2)
	# Fahne
	k.box(c + Vector3(0, h + 0.05 + h * 0.6 + 0.1, 0), Vector3(0.012, 0.22, 0.012), Color(0.3, 0.2, 0.1))
	k.box(c + Vector3(0.07, h + 0.05 + h * 0.6 + 0.19, 0), Vector3(0.13, 0.07, 0.01), Color(0.78, 0.14, 0.14))


func _castle(ti: int, tj: int) -> void:
	var k := MeshKit.new()
	var stone := Color(0.56, 0.55, 0.58)
	var dark := Color(0.4, 0.4, 0.45)
	var roof := Color(0.22, 0.3, 0.62)
	var r := 0.4
	var wh := 0.4
	# Sockel aus grobem Fels
	k.box(Vector3(0, 0.03, 0), Vector3(r * 2.3, 0.06, r * 2.3), Color(0.45, 0.43, 0.4))
	# Mauern (Hinten, Links, Rechts, Vorne mit Tor)
	k.box(Vector3(0, wh * 0.5 + 0.06, -r), Vector3(2 * r, wh, 0.1), stone)
	k.box(Vector3(-r, wh * 0.5 + 0.06, 0), Vector3(0.1, wh, 2 * r), stone)
	k.box(Vector3(r, wh * 0.5 + 0.06, 0), Vector3(0.1, wh, 2 * r), stone)
	k.box(Vector3(-0.27, wh * 0.5 + 0.06, r), Vector3(0.26, wh, 0.1), stone)
	k.box(Vector3(0.27, wh * 0.5 + 0.06, r), Vector3(0.26, wh, 0.1), stone)
	k.box(Vector3(0, wh * 0.82 + 0.06, r), Vector3(0.28, wh * 0.36, 0.1), stone)            # Torsturz
	# Wehrgang und Zinnen
	for z in [-r, r]:
		k.box(Vector3(0, wh + 0.07, z), Vector3(2 * r, 0.025, 0.14), dark)
	for x in [-r, r]:
		k.box(Vector3(x, wh + 0.07, 0), Vector3(0.14, 0.025, 2 * r), dark)
	_crenel(k, Vector3(-r + 0.1, 0, -r), Vector3(r - 0.1, 0, -r), wh + 0.11, dark, 6)
	_crenel(k, Vector3(-r, 0, -r + 0.1), Vector3(-r, 0, r - 0.1), wh + 0.11, dark, 6)
	_crenel(k, Vector3(r, 0, -r + 0.1), Vector3(r, 0, r - 0.1), wh + 0.11, dark, 6)
	_crenel(k, Vector3(-r + 0.1, 0, r), Vector3(-0.17, 0, r), wh + 0.11, dark, 2)
	_crenel(k, Vector3(0.17, 0, r), Vector3(r - 0.1, 0, r), wh + 0.11, dark, 2)
	# Tor: dunkler Durchgang, Holztor mit Beschlaegen, Fallgitter, Fackeln
	k.box(Vector3(0, 0.2, r + 0.005), Vector3(0.2, 0.28, 0.104), Color(0.07, 0.05, 0.06))
	k.box(Vector3(0, 0.19, r + 0.052), Vector3(0.17, 0.25, 0.012), Color(0.34, 0.21, 0.11))
	for gx in [-0.05, 0.0, 0.05]:
		k.box(Vector3(gx, 0.19, r + 0.06), Vector3(0.012, 0.25, 0.008), Color(0.2, 0.2, 0.22))
	k.box(Vector3(0, 0.12, r + 0.06), Vector3(0.17, 0.014, 0.008), Color(0.2, 0.2, 0.22))
	k.box(Vector3(0, 0.27, r + 0.058), Vector3(0.2, 0.025, 0.012), Color(0.3, 0.3, 0.34))                # Gitterkopf
	for fx in [-0.15, 0.15]:
		k.box(Vector3(fx, 0.25, r + 0.07), Vector3(0.015, 0.06, 0.015), Color(0.3, 0.2, 0.1))
		k.box(Vector3(fx, 0.29, r + 0.07), Vector3(0.03, 0.03, 0.03), Color(1.0, 0.7, 0.2))
	# Vier Eckturme
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_tower(k, Vector3(sx * r, 0.06, sz * r), 0.1, 0.62, stone, dark, roof)
	# Bergfried mit Erker, Fenstern und grosser Fahne
	k.box(Vector3(0, 0.42, -0.18), Vector3(0.34, 0.72, 0.34), stone.lightened(0.04))
	k.box(Vector3(0, 0.8, -0.18), Vector3(0.4, 0.05, 0.4), dark)
	for n in 8:
		var a3 := TAU * n / 8.0
		var d3 := Vector3(cos(a3), 0, sin(a3))
		k.box(Vector3(0, 0.86, -0.18) + Vector3(sign(d3.x) * 0.17 * (1 if absf(d3.x) > 0.3 else 0), 0, sign(d3.z) * 0.17 * (1 if absf(d3.z) > 0.3 else 0)), Vector3(0.07, 0.07, 0.07), dark)
	k.frustum(Vector3(0, 0.83, -0.18), 0.25, 0.0, 0.34, Color(0.6, 0.18, 0.14), Color(0.82, 0.3, 0.2), 4)
	for wz in [0.0, 0.14]:
		k.box(Vector3(wz * 0 + (-0.07 if wz == 0.0 else 0.07), 0.58, -0.18 + 0.172), Vector3(0.07, 0.12, 0.012), Color(0.98, 0.84, 0.45))
	k.box(Vector3(0, 0.34, -0.18 + 0.172), Vector3(0.1, 0.2, 0.012), Color(0.25, 0.16, 0.09))
	k.box(Vector3(0, 1.28, -0.18), Vector3(0.015, 0.4, 0.015), Color(0.3, 0.2, 0.1))
	k.box(Vector3(0.1, 1.38, -0.18), Vector3(0.2, 0.12, 0.01), Color(0.78, 0.14, 0.14))
	k.box(Vector3(0.1, 1.38, -0.185), Vector3(0.07, 0.07, 0.01), Color(0.95, 0.8, 0.3))
	_build_mesh_at(k, ti, height_at(ti, tj), tj, "Castle_%d_%d" % [ti, tj])
