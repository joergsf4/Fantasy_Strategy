class_name HistoryChart
extends Control
## Kleine Verlaufsgrafik im Statistik-Bildschirm: Leben der Gruppe (Anteil, gold) und Zahl der Gegner (rot) je Runde.

var history: Array = []


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.25))
	for i in 3:
		var y := h * float(i) / 2.0
		draw_line(Vector2(0, y), Vector2(w, y), Color(1, 1, 1, 0.08), 1.0)
	if history.size() < 2:
		return
	var max_foes := 1
	for e: Dictionary in history:
		max_foes = maxi(max_foes, int(e["foes"]))
	var hp_pts := PackedVector2Array()
	var foe_pts := PackedVector2Array()
	for i in history.size():
		var e: Dictionary = history[i]
		var x := w * float(i) / float(history.size() - 1)
		var hp := float(e["hp"]) / maxf(1.0, float(e["maxhp"]))
		hp_pts.append(Vector2(x, h - 4 - (h - 8) * hp))
		foe_pts.append(Vector2(x, h - 4 - (h - 8) * float(e["foes"]) / float(max_foes)))
	draw_polyline(foe_pts, Color(1.0, 0.42, 0.35), 2.0, true)
	draw_polyline(hp_pts, Color(1.0, 0.83, 0.42), 2.5, true)
	for p in hp_pts:
		draw_circle(p, 3.0, Color(1.0, 0.83, 0.42))
