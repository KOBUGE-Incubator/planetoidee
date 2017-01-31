extends Control

func play(shortcuts = false):
	Globals.set("shortcuts_enabled", shortcuts)
	get_tree().change_scene("res://game/render.tscn")
