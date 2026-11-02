class_name ShortClip
extends Trailer3
## YouTube Short (ca. 30 Sekunden, wird per ffmpeg ins Hochformat gesetzt): Titelbild, kurze Level-Einleitung (Schurke gegen Held),
## zwei schnelle Kampfausschnitte, zwei lustige Faehigkeiten, eine geheime Attacke, Abspann. Aufnahme und Hochformat: tools/make_short.sh

const SHORT_INTRO := [
	{"left": "samurai", "right": "wart", "speaker": "samurai", "left_expr": "wuetend", "text": "Halt, Schurke! Dein Treiben endet hier!"},
	{"left": "samurai", "right": "wart", "speaker": "wart", "right_expr": "lachend", "text": "Ha! Versuch's doch, Held! Raketen frei!"},
]
const SHORT_BATTLE_1 := {"map": "ch3", "fire": true, "cam": [0.0, 4.2, 4.4], "fov": 38, "max_heroes": 3, "max_foes": 3, "speed": 2.2,
	"p": [["ritter", "p", [4, 6]], ["samurai", "p", [4, 7]], ["kungfu", "p", [3, 6]]],
	"e": [["soldat_infanterie", "e", [6, 6]], ["soldat_infanterie", "e", [6, 7]], ["soldat_beritten", "e", [7, 6]]]}
const SHORT_BATTLE_2 := {"map": "ch7", "fire": false, "cam": [0.0, 4.2, 4.4], "fov": 38, "max_heroes": 3, "max_foes": 3, "speed": 2.2,
	"p": [["robo", "p", [4, 6]], ["hund", "p", [4, 7]], ["ninjas", "p", [3, 6]]],
	"e": [["soldat_infanterie", "e", [6, 7]], ["soldat_beritten", "e", [7, 6]], ["soldat_infanterie", "e", [6, 6]]]}


func _run() -> void:
	talk_compact = true
	# --- Titelbild
	_play_music(TITLE_MUSIC, -4.0)
	stage.set_mode("title")
	var title := TitleScreen.new()
	add_child(title)
	_fade.color.a = 0.0
	await _wait(4.4)
	await _fade_to(1.0, 0.3)
	title.queue_free()

	# --- kurze Einleitung eines Levels: Held gegen Schurke
	await _talk("ch2", SHORT_INTRO)

	# --- zwei schnelle Kaempfe
	_play_music(BATTLE_MUSIC, -4.0)
	await _battle(SHORT_BATTLE_1)
	await _battle(SHORT_BATTLE_2)

	# --- zwei Faehigkeiten
	await _fade_to(1.0, 0.1)
	stage.map_data = Mission.load_mission("ch1")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	Engine.time_scale = 1.4
	await _scene(SCENES_A[0])      # Fasswurf
	await _scene(SCENES_A[2])      # Polymorph (Frosch)
	Engine.time_scale = 1.0

	# --- geheime Attacke
	await _fade_to(1.0, 0.1)
	await _secret_short()
	stage.map_data = Mission.load_mission("ch1")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	stage.battle.super_music = _duck
	Engine.time_scale = 1.15
	await _scene(DRUNKEN)
	Engine.time_scale = 1.0

	# --- Abspann
	await _fade_to(1.0, 0.2)
	_say("")
	_fade_out_music(1.4)
	await _end_card3()
	get_tree().quit()
