extends Node3D


var multiplayer_peer = ENetMultiplayerPeer.new()


func _on_join_button_up():
	var port = str($CanvasLayer/Menu/Port.text).to_int()
	
	multiplayer_peer.create_client("localhost", port)
	multiplayer.multiplayer_peer = multiplayer_peer
	
	$CanvasLayer/Menu.visible = false


func _on_host_button_up():
	var port = str($CanvasLayer/Menu/Port.text).to_int()
	
	multiplayer_peer.create_server(port)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(func(id): add_player_character(id))
	
	$CanvasLayer/Menu.visible = false
	add_player_character()


func add_player_character(id = 1):
	var character = preload("res://Player.tscn").instantiate()
	character.name = str(id)
	add_child(character)
