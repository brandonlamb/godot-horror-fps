extends Control

func _ready():
	set_process(true);
	set_process_input(true);

func _input(ie):
	if ie.type == InputEvent.KEY:
		if ie.pressed && ie.scancode == KEY_ESCAPE:
			get_tree().call_deferred("quit");

func _process(delta):
	var fps = OS.get_frames_per_second();
	var debugtext = "FPS: "+str(int(fps))+" | Frametime: "+str(delta);
	debugtext += "\nDraw Calls: "+str(Performance.get_monitor(Performance.RENDER_DRAW_CALLS_IN_FRAME));
	get_node("lblFPS").set_text(debugtext);