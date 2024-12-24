extends Node3D


var multiplayer_peer = ENetMultiplayerPeer.new()


func _process(delta):
	pass


func _on_join_button_up():
	var port = str($CanvasLayer/Menu/Port.text).to_int()
	
	multiplayer_peer.create_client("192.168.1.122", port)
	multiplayer.multiplayer_peer = multiplayer_peer
	
	$CanvasLayer/Menu.visible = false


func _on_host_button_up():
	var port = str($CanvasLayer/Menu/Port.text).to_int()
	
	multiplayer_peer.create_server(port)
	multiplayer.multiplayer_peer = multiplayer_peer
	
	multiplayer_peer.peer_connected.connect(func(id): add_player_character(id))
	multiplayer_peer.peer_disconnected.connect(func(id): $NetworkedNodes.get_node(str(id)).queue_free())
	
	$CanvasLayer/Menu.visible = false
	add_player_character()


func add_player_character(id = 1):
	
	print("Player connected. ID: ", id)
	var character = preload("res://Player.tscn").instantiate()
	character.name = str(id)
	$NetworkedNodes.add_child(character, true)
	
	character.tree_exited.connect(func(): add_player_character(id))
