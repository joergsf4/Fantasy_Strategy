class_name MeshKit
extends RefCounted
## Kleiner Mesh-Baukasten mit Vertexfarben (Boxen, Kegel/Zylinder, Blobs). Godot-Front = im Uhrzeigersinn.

var verts := PackedVector3Array()
var norms := PackedVector3Array()
var cols := PackedColorArray()
var idx := PackedInt32Array()

static var _ico_cache := {}


func _v(p: Vector3, n: Vector3, c: Color) -> int:
	verts.append(p)
	norms.append(n)
	cols.append(c)
	return verts.size() - 1


func _quad(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, c: Color) -> void:
	# p0..p3 gegen den Uhrzeigersinn von aussen gesehen
	var n := (p1 - p0).cross(p3 - p0).normalized()
	var a := _v(p0, n, c)
	var b := _v(p1, n, c)
	var cc := _v(p2, n, c)
	var d := _v(p3, n, c)
	idx.append_array([a, cc, b, a, d, cc])


func box(center: Vector3, size: Vector3, c: Color, rot_y := 0.0) -> void:
	var h := size * 0.5
	var bs := Basis(Vector3.UP, rot_y)
	var P := func(sx: float, sy: float, sz: float) -> Vector3:
		return center + bs * Vector3(sx * h.x, sy * h.y, sz * h.z)
	var top := c.lightened(0.12)
	_quad(P.call(1, -1, 1), P.call(1, -1, -1), P.call(1, 1, -1), P.call(1, 1, 1), c)
	_quad(P.call(-1, -1, -1), P.call(-1, -1, 1), P.call(-1, 1, 1), P.call(-1, 1, -1), c.darkened(0.08))
	_quad(P.call(-1, 1, 1), P.call(1, 1, 1), P.call(1, 1, -1), P.call(-1, 1, -1), top)
	_quad(P.call(-1, -1, -1), P.call(1, -1, -1), P.call(1, -1, 1), P.call(-1, -1, 1), c.darkened(0.3))
	_quad(P.call(-1, -1, 1), P.call(1, -1, 1), P.call(1, 1, 1), P.call(-1, 1, 1), c)
	_quad(P.call(1, -1, -1), P.call(-1, -1, -1), P.call(-1, 1, -1), P.call(1, 1, -1), c.darkened(0.08))


## Kegelstumpf (r1 = 0 -> Kegel) mit glatten Normalen, optional Deckel.
func frustum(base: Vector3, r0: float, r1: float, height: float, c_bottom: Color, c_top: Color, seg := 8, cap := false) -> void:
	var rows: Array[PackedInt32Array] = []
	for k in 2:
		var r := r0 if k == 0 else r1
		var y := 0.0 if k == 0 else height
		var col := c_bottom if k == 0 else c_top
		var ring := PackedInt32Array()
		for i in seg + 1:
			var a := TAU * i / seg
			var n := Vector3(cos(a) * height, r0 - r1, sin(a) * height).normalized()
			ring.append(_v(base + Vector3(cos(a) * r, y, sin(a) * r), n, col))
		rows.append(ring)
	for i in seg:
		idx.append_array([rows[0][i], rows[0][i + 1], rows[1][i + 1], rows[0][i], rows[1][i + 1], rows[1][i]])
	if cap and r1 > 0.0:
		var ctr := _v(base + Vector3(0, height, 0), Vector3.UP, c_top)
		for i in seg:
			var a0 := TAU * i / seg
			var a1 := TAU * (i + 1) / seg
			var p0 := _v(base + Vector3(cos(a0) * r1, height, sin(a0) * r1), Vector3.UP, c_top)
			var p1 := _v(base + Vector3(cos(a1) * r1, height, sin(a1) * r1), Vector3.UP, c_top)
			idx.append_array([ctr, p0, p1])


## Satteldach (Prisma entlang X). Gelegt auf Hoehe base.y, First hoch ridge.
func gable_roof(base: Vector3, size: Vector3, ridge: float, c: Color, rot_y := 0.0) -> void:
	var bs := Basis(Vector3.UP, rot_y)
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var P := func(x: float, y: float, z: float) -> Vector3:
		return base + bs * Vector3(x, y, z)
	_quad(P.call(-hx, 0, hz), P.call(hx, 0, hz), P.call(hx, ridge, 0), P.call(-hx, ridge, 0), c)
	_quad(P.call(hx, 0, -hz), P.call(-hx, 0, -hz), P.call(-hx, ridge, 0), P.call(hx, ridge, 0), c.darkened(0.12))
	var gc := c.darkened(0.25)
	var n1 := bs * Vector3(1, 0, 0)
	var a := _v(P.call(hx, 0, hz), n1, gc)
	var b := _v(P.call(hx, 0, -hz), n1, gc)
	var d := _v(P.call(hx, ridge, 0), n1, gc)
	idx.append_array([a, b, d])
	var n2 := -n1
	var e := _v(P.call(-hx, 0, -hz), n2, gc)
	var f := _v(P.call(-hx, 0, hz), n2, gc)
	var g := _v(P.call(-hx, ridge, 0), n2, gc)
	idx.append_array([e, f, g])


static func _ico(subdiv: int) -> Array:
	if _ico_cache.has(subdiv):
		return _ico_cache[subdiv]
	var t := (1.0 + sqrt(5.0)) / 2.0
	var v: Array[Vector3] = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for i in v.size():
		v[i] = v[i].normalized()
	var f: Array = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2],
		[10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11],
		[6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for s in subdiv:
		var cache := {}
		var nf: Array = []
		var mid := func(a: int, b: int) -> int:
			var key := Vector2i(mini(a, b), maxi(a, b))
			if not cache.has(key):
				v.append(((v[a] + v[b]) * 0.5).normalized())
				cache[key] = v.size() - 1
			return cache[key]
		for tri: Array in f:
			var ab: int = mid.call(tri[0], tri[1])
			var bc: int = mid.call(tri[1], tri[2])
			var ca: int = mid.call(tri[2], tri[0])
			nf.append([tri[0], ab, ca])
			nf.append([tri[1], bc, ab])
			nf.append([tri[2], ca, bc])
			nf.append([ab, bc, ca])
		f = nf
	_ico_cache[subdiv] = [v, f]
	return _ico_cache[subdiv]


## Unregelmaessige Kugel (Baumkrone, Busch, Fels). smooth=false -> kantig (Fels).
func blob(center: Vector3, radii: Vector3, c_bottom: Color, c_top: Color, jitter: float, noise: FastNoiseLite, subdiv := 2, smooth := true) -> void:
	var ico := _ico(subdiv)
	var src: Array[Vector3] = ico[0]
	var faces: Array = ico[1]
	var pts := PackedVector3Array()
	for d in src:
		var k := 1.0 + jitter * noise.get_noise_3dv(d * 2.0 + center * 3.0)
		pts.append(center + d * radii * k)
	var base := verts.size()
	if smooth:
		var nrm := PackedVector3Array()
		nrm.resize(pts.size())
		for f: Array in faces:
			var fn := (pts[f[1]] - pts[f[0]]).cross(pts[f[2]] - pts[f[0]])
			for i in 3:
				nrm[f[i]] += fn
		for i in pts.size():
			var t := clampf((src[i].y + 1.0) * 0.5, 0.0, 1.0)
			_v(pts[i], nrm[i].normalized(), c_bottom.lerp(c_top, t))
		for f: Array in faces:
			idx.append_array([base + f[0], base + f[2], base + f[1]])
	else:
		for f: Array in faces:
			var fn := (pts[f[1]] - pts[f[0]]).cross(pts[f[2]] - pts[f[0]]).normalized()
			var t := clampf((src[f[0]].y + 1.0) * 0.5, 0.0, 1.0)
			var col := c_bottom.lerp(c_top, t)
			var a := _v(pts[f[0]], fn, col)
			var b := _v(pts[f[1]], fn, col)
			var d := _v(pts[f[2]], fn, col)
			idx.append_array([a, d, b])


func build() -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m
