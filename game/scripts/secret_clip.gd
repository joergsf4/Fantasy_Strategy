class_name SecretClip
extends Trailer2
## Kurzer Mitschnitt eines Geheimnisses im Spiel (zum Zeigen): Aufnahme mit
##   CLIP_SECRET=futter_fuer_brumm SHOT=secretclip godot --path game --write-movie out.avi --fixed-fps 30   (siehe tools/make_clip.sh)
## Die Szene und der Effekt laufen so ab wie im Kampf (erstes Mal: Dialogszene, ggf. Polarlicht-Auftritt, danach der Effekt, dann ein zweites Mal kurz).

const SPECS := {
	"inspiration_von_oben": {"ab": "sternschnuppe", "u": ["magical_girl", "p", [1, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["ritter", "p", [5, 7]], ["kungfu", "p", [2, 6]], ["soldat_beritten", "e", [7, 6]]], "cam": [1.4, 5.2, 5.6], "fov": 40},
	"woll_im_ueberfluss": {"ab": "kanone", "u": ["elisabeth", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["wendy", "p", [3, 8]], ["ritter", "p", [4, 8]], ["kungfu", "p", [2, 6]], ["soldat_beritten", "e", [7, 6]]], "cam": [0.4, 5.0, 5.4], "fov": 40},
	"shuriken_regen": {"throw": true, "u": ["museklaugust", "p", [2, 7]], "t": ["ninjas", "p", [3, 7]], "dest": [6, 7], "more": [["soldat_infanterie", "e", [7, 7]], ["soldat_beritten", "e", [7, 8]], ["soldat_bogenschuetze", "e", [8, 6]], ["soldat_infanterie", "e", [10, 3]]], "cam": [3.0, 8.0, 5.0], "fov": 46},
	"futter_fuer_brumm": {"ab": "knochenwurf", "u": ["hund", "p", [2, 7]], "t": ["soldat_infanterie", "e", [4, 7]], "more": [["maedchen_baer", "p", [3, 7], {"hp": 18}], ["soldat_infanterie", "e", [6, 7]]], "cam": [0.2, 3.0, 4.6], "fov": 36},
	"laser_reflektor": {"ab": "roter_laser", "u": ["robo", "p", [2, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["samurai", "p", [4, 7]], ["soldat_infanterie", "e", [4, 5]], ["soldat_beritten", "e", [5, 8]], ["soldat_infanterie", "e", [4, 9]]], "cam": [1.0, 3.6, 5.4], "fov": 38},
}


func _run() -> void:
	var id := OS.get_environment("CLIP_SECRET")
	var sec := Secrets.by_id(id)
	_play_music(BATTLE_MUSIC, -4.0)
	stage.set_mode("battle")
	_prep_battle()
	var b := stage.battle
	b.super_music = _duck_clip
	b.secret_runner = func(s: Dictionary) -> void: await _play_scene(s)
	var sc: Dictionary = SPECS.get(id, SPECS["futter_fuer_brumm"])
	_fade.color.a = 1.0
	await _scene(sc)                  # erstes Mal: Szene (und Auftritt), dann der Effekt
	await _wait(0.6)
	_say("Beim zweiten Mal nur der Effekt")
	var hero: Dictionary = b.units.filter(func(u: Dictionary) -> bool: return u["id"] == sc["u"][0])[0]
	await _scene(sc)
	_fade_out_music(1.0)
	await _fade_to(1.0, 0.5)
	get_tree().quit()


func _duck_clip(on: bool) -> void:
	if _music != null and is_instance_valid(_music):
		create_tween().tween_property(_music, "volume_db", -30.0 if on else -4.0, 0.3)


## Die Dialogszene des Geheimnisses wie im Spiel, Zeilen laufen automatisch weiter.
func _play_scene(sec: Dictionary) -> void:
	var names := {}
	for uid: String in unit_defs:
		names[uid] = unit_defs[uid]["name"]
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.5)
	dim.size = Vector2(1280, 720)
	layer.add_child(dim)
	var d := SecretScene.new()
	d.setup_secret(sec, names)
	layer.add_child(d)
	await _wait(3.4)
	var lines: Array = sec["scene"]["lines"]
	for i in lines.size():
		await _wait(0.3 + String(lines[i]["text"]).length() * 0.025 + 0.9)
		d._advance()
	await _wait(0.2)
	layer.queue_free()
