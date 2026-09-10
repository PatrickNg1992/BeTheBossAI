extends CanvasLayer


func _on_host_button_pressed() -> void:
	NetworkManager.host_game()


func _on_client_button_pressed() -> void:
	NetworkManager.join_game()
