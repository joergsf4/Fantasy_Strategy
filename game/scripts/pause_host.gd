class_name PauseHost
extends Node
## Haengt direkt unter dem Wurzelknoten und laeuft auch bei angehaltenem Spiel: Esc oeffnet/schliesst das Pause-Menue, F11 schaltet Vollbild.
## Speichern und Beenden erledigt der Aufrufer (Main) ueber die Callables.

var save_cb := Callable()       # func() -> void
var quit_cb := Callable()       # func() -> void
var can_restart_cb := Callable()  # func() -> bool: laeuft gerade ein Kampf?
var restart_cb := Callable()      # func() -> void: Kampf neu beginnen
var can_save_cb := Callable()   # func() -> bool: gibt es schon einen Spielstand zu sichern (nicht im Hauptmenue)?
var _layer: CanvasLayer
var _menu: PauseMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_open() -> bool:
	return _menu != null and is_instance_valid(_menu)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if is_open():
			_menu.close()
		else:
			open()
	elif event.keycode == KEY_F11:
		get_viewport().set_input_as_handled()
		toggle_fullscreen()


func open() -> void:
	if is_open():
		return
	_layer = CanvasLayer.new()
	_layer.layer = 40
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	_menu = PauseMenu.new()
	_menu.can_save = can_save_cb.call() if can_save_cb.is_valid() else false
	_menu.can_restart = can_restart_cb.call() if can_restart_cb.is_valid() else false
	_menu.restart_requested.connect(func() -> void:       # Mission neu starten: Menue zu, Spiel weiter, Kampf von vorn
		get_tree().paused = false
		_menu.close()
		if restart_cb.is_valid():
			restart_cb.call())
	_menu.save_requested.connect(func() -> void:
		if save_cb.is_valid():
			save_cb.call())
	_menu.quit_requested.connect(func() -> void:
		if save_cb.is_valid() and _menu.can_save:
			save_cb.call()
		if quit_cb.is_valid():
			quit_cb.call()
		else:
			get_tree().quit())
	_menu.menu_requested.connect(func() -> void:       # zurueck zum Hauptmenue: Stand sichern, Spiel anhalten beenden, Szene neu laden
		if save_cb.is_valid() and _menu.can_save:
			save_cb.call()
		get_tree().paused = false
		var tree := get_tree()
		queue_free()
		tree.reload_current_scene())
	_menu.fullscreen_toggled.connect(toggle_fullscreen)
	_menu.closed.connect(func() -> void:
		if is_instance_valid(_layer):
			_layer.queue_free())
	_layer.add_child(_menu)


static func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]


static func set_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
	Settings.set_value("window", 1 if on else 0)      # F11 und Pause-Menue halten die Grafikoption mit


static func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())
