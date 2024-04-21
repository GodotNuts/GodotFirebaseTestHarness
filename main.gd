extends Node2D

func _ready():
	pass

func _on_auth_tests_pressed():
	get_tree().change_scene_to_file("res://tests/auth/auth.tscn")


func _on_firestore_tests_pressed():
	get_tree().change_scene_to_file("res://tests/firestore/firestore.tscn")


func _on_rtd_tests_pressed():
	get_tree().change_scene_to_file("res://tests/database/database.tscn")


func _on_storage_tests_pressed():
	get_tree().change_scene_to_file("res://tests/storage/storage.tscn")


func _on_dynamiclinks_tests_pressed():
	get_tree().change_scene_to_file("res://tests/links/links.tscn")
