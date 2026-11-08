extends SceneTree

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func find_line(lines: Array, fragment: String, speaker: String) -> int:
	for i in lines.size():
		var line: Dictionary = lines[i]
		if line.get("speaker", "") == speaker and fragment in line.get("text", ""):
			return i
	return -1


func _initialize() -> void:
	var stories := {}
	for chapter in [17, 18, 19, 20]:
		var path := "res://data/story_ch%d.json" % chapter
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			check(false, "Ungueltige Storydaten: " + path)
			quit(1)
			return
		stories[chapter] = parsed

	check(find_line(stories[17]["intro"], "Er gehört zu uns", "maedchen_baer") >= 0, "Versprechen nach der Entfuehrung")
	check(find_line(stories[18]["intro"], "wie es dem Sack geht", "maedchen_baer") >= 0, "Sorge im Schnee")
	check(find_line(stories[18]["intro"], "Geruch von einem Freund", "hund") >= 0, "Brumm will den Sack wiederfinden")
	var ch19: Array = stories[19]["outro"]
	check(find_line(ch19, "Er ist unser Freund", "maedchen_baer") >= 0, "Sack bleibt mehr als ein Haendler")
	check(find_line(ch19, "wissen sie vielleicht, wo der Sack ist", "maedchen_baer") >= 0, "Hogsmeat als Spur")

	var intro: Array = stories[20]["intro"]
	var demand := find_line(intro, "Gebt uns unseren Sack wieder", "maedchen_baer")
	var insult := find_line(intro, "blauen Wollbeutel", "frischlinge")
	var friend := find_line(intro, "Er ist unser Freund", "maedchen_baer")
	var reveal := find_line(intro, "beim Meister auf dem Berg", "frischlinge")
	check(demand >= 0 and demand < insult and insult < friend and friend < reveal, "Konfrontation und Enthuellung in Hogsmeat")
	var outro: Array = stories[20]["outro"]
	var rescue := find_line(outro, "Wir kommen dich holen", "maedchen_baer")
	check(find_line(outro, "Der Sack ist also beim Meister", "maedchen_baer") >= 0 and rescue >= 0, "Rettung bleibt nach dem Kampf ein Ziel")
	if rescue >= 0:
		var with_dog := Mission.voiced([outro[rescue]], ["maedchen_baer", "hund"])
		var without_dog := Mission.voiced([outro[rescue]], ["maedchen_baer"])
		check(with_dog[0]["speaker"] == "hund" and without_dog[0]["speaker"] == "maedchen_baer", "Rettungsversprechen mit optionalem Brumm und Mira als Rueckfall")
	check(not Mission.dialogue_ids("ch20").has("hund"), "Brumm wird in Hogsmeat nicht zur Pflichtfigur")
	var mission := Mission.load_mission("ch20")
	check(mission["triggers"][0]["when"]["flee"] == "frischlinge" and mission["triggers"][0]["do"][0]["spawn"][0]["id"] == "cyborg_wart", "Robowart erscheint weiterhin nach der Flucht")
	print("sack_story: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
