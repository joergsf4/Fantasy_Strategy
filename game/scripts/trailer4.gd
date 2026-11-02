class_name Trailer4
extends Trailer3
## Trailer 4 (ca. 80 Sekunden) fuer YouTube: wenige Figuren, dafuer laenger (Robo, Hundsfreund, Elisabeth, Takeda), Kaempfe im Wuestenbiom und
## im Gebirge, lustige Faehigkeit, Ueberfahrt mit dem seekranken Hund, Geheimnis Laser-Reflektor, Abspann. Ohne Regent, Zahlen und Bienenkorb.
## Aufnahme: tools/make_trailer.sh trailer4

const T4_SEA_TALK := [
	{"left": "hund", "right": "elisabeth", "speaker": "hund", "left_expr": "seekrank", "text": "Mir ist schlecht. Hab ich erwähnt, dass mir schlecht ist?"},
	{"left": "hund", "right": "elisabeth", "speaker": "elisabeth", "right_expr": "lachend", "text": "Schau zum Horizont, Landratte, nicht auf die Wellen."},
	{"left": "hund", "right": "elisabeth", "speaker": "hund", "left_expr": "seekrank", "text": "Der Horizont schwankt auch! Alles schwankt!"},
]
const T4_BATTLE_DESERT := {"map": "ch7", "fire": false, "cam": [0.0, 6.0, 6.2], "fov": 38, "max_heroes": 4, "max_foes": 3, "speed": 1.35,
	"p": [["robo", "p", [3, 6]], ["hund", "p", [3, 7]], ["elisabeth", "p", [2, 7]], ["samurai", "p", [2, 6]]],
	"e": [["soldat_infanterie", "e", [7, 7]], ["soldat_beritten", "e", [8, 6]], ["soldat_infanterie", "e", [8, 7]], ["soldat_bogenschuetze", "e", [9, 7]], ["soldat_infanterie", "e", [7, 6]]]}
const T4_BATTLE_MOUNTAIN := {"map": "ch9", "fire": false, "cam": [0.0, 6.0, 6.2], "fov": 38, "max_heroes": 4, "max_foes": 3, "speed": 1.35,
	"p": [["robo", "p", [3, 6]], ["hund", "p", [2, 6]], ["samurai", "p", [3, 7]], ["elisabeth", "p", [2, 7]]],
	"e": [["wart", "e", [7, 5]], ["frischlinge", "e", [6, 6]], ["soldat_infanterie", "e", [7, 7]], ["soldat_bogenschuetze", "e", [8, 6]]]}
const T4_LASER := {"ab": "roter_laser", "u": ["robo", "p", [2, 7]], "t": ["soldat_infanterie", "e", [7, 7]],
	"more": [["samurai", "p", [4, 7]], ["soldat_infanterie", "e", [5, 6]], ["soldat_beritten", "e", [5, 8]], ["soldat_bogenschuetze", "e", [6, 8]]],
	"cam": [1.0, 3.2, 5.8], "fov": 38}
const T4_TALK_WART := [
	{"left": "ritter", "right": "wart", "speaker": "wart", "right_expr": "lachend", "text": "Na, wen haben wir denn da? Diesmal bin ich nicht allein, ich hab meine Jungs mitgebracht."},
	{"left": "ritter", "right": "frischlinge", "speaker": "frischlinge", "right_expr": "wuetend", "text": "Chef, dürfen wir sie hauen? Bitte!"},
]


func _run() -> void:
	# --- Mira, dann zwei Figuren mit mehr Zeit
	_play_music(TITLE_MUSIC, -4.0)
	stage.set_mode("title")
	_fade.color.a = 1.0
	await _fade_to(0.0, 0.7)
	_say("Ein Mädchen. Ein Bär.")
	await _wait(1.2)
	stage.set_mode("dialog")
	await _beat([["maedchen_baer", "wuetend", "Mira & Brumm", "Der Anfang einer Legende"], []], 2.0)
	_say("Sammle deine Helden")
	await _beat([["robo", "", "Robo", "Dampfroboter"], []], 2.2)
	await _beat([["hund", "wuetend", "Blauer Hundsfreund", "Knochenkämpfer"], []], 2.2)
	await _beat([["elisabeth", "lachend", "Käpt’n Elisabeth", "Piratin mit Kanone"], ["samurai", "wuetend", "Takeda", "Samurai"]], 2.4)

	# --- Kampf in der Wueste
	await _fade_to(1.0, 0.12)
	_say("Kämpfe in rauen Landstrichen")
	_play_music(BATTLE_MUSIC, -4.0)
	await _battle(T4_BATTLE_DESERT)

	# --- lustige Faehigkeiten
	_say("Spezialfähigkeiten mit Humor")
	stage.map_data = Mission.load_mission("ch1")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	Engine.time_scale = 1.4
	await _scene(SCENES_B[0])      # Bellen
	await _scene(SCENES_A[0])      # Fasswurf
	await _scene({"ab": "roter_laser", "u": ["robo", "p", [2, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_beritten", "e", [7, 6]]], "cam": [0.6, 3.0, 5.4], "fov": 38})
	await _scene(SCENES_B[2])      # Tonikum
	Engine.time_scale = 1.0

	# --- Wart und August, dann der Wurf ueber die Mauer
	_say("Mauer? Kein Problem.")
	await _talk("ch2", TALK_WART)
	await _throw_scene()

	# --- Ueberfahrt mit dem seekranken Hund
	_say("Über das Meer zu neuen Ufern")
	_fade_out_music(1.0)
	await _sea_talk()

	# --- Gebirge, Wart und seine Frischlinge
	_say("Gegner mit Charakter")
	_play_music(BATTLE_MUSIC, -4.0)
	await _battle(T4_BATTLE_MOUNTAIN)

	# --- Geheimnis: Laser-Reflektor
	await _fade_to(1.0, 0.12)
	_say("Manche Geheimnisse entdeckt man nur zu zweit")
	await _secret_short("laser_reflektor")
	stage.map_data = Mission.load_mission("ch7")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	stage.battle.super_music = _duck
	Engine.time_scale = 1.1
	await _scene(T4_LASER)
	Engine.time_scale = 1.0

	# --- Siegerehrung
	await _fade_to(1.0, 0.15)
	_say("Siegerehrung mit Statistik")
	stage.map_data = Mission.load_mission("ch1")
	stage.new_battle()
	stage.set_mode("dialog")
	_play_music("res://assets/audio/sieg_statistik.mp3", -4.0)
	await _stats_screen()

	# --- Haendler und Abspann
	_say("Rüste dich aus")
	await _beat([["haendler", "lachend", "Sack", "Lebender Wollsack, Händler"], []], 2.0)
	await _fade_to(1.0, 0.2)
	_say("")
	_fade_out_music(1.6)
	await _end_card3()
	get_tree().quit()


## Dialog auf dem Meer (Meer-Szene wie in der Ueberfahrt nach Mission 6), Zeilen automatisch weiterschalten.
func _sea_talk() -> void:
	await _fade_to(1.0, 0.12)
	var names := {}
	for id: String in unit_defs:
		names[id] = unit_defs[id]["name"]
	var sea_layer := CanvasLayer.new()
	sea_layer.layer = 3
	add_child(sea_layer)
	var it := Interlude.new()
	it.setup({"scene": "sea", "dir": "right", "speed": 1.8, "hold": true, "duration": 600.0})
	sea_layer.add_child(it)
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var d := Dialogue.new()
	d.setup(T4_SEA_TALK, names)
	layer.add_child(d)
	await _fade_to(0.0, 0.2)
	await _wait(1.0)
	for i in T4_SEA_TALK.size():
		await _wait(0.8 + String(T4_SEA_TALK[i]["text"]).length() * 0.06 + 0.9)
		d._advance()
	await _fade_to(1.0, 0.15)
	layer.queue_free()
	sea_layer.queue_free()
