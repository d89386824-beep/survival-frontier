extends Node
## ENet session foundation. Dedicated authoritative server is the intended deployment model.

signal status_changed(message: String)
signal player_joined(peer_id: int)
signal player_left(peer_id: int)

const DEFAULT_PORT := 27015
const MAX_PLAYERS := 100

var is_server := false
var connected := false
var peer: ENetMultiplayerPeer

func host(port: int = DEFAULT_PORT) -> Error:
    peer = ENetMultiplayerPeer.new()
    var error := peer.create_server(port, MAX_PLAYERS - 1)
    if error != OK:
        status_changed.emit("Не удалось запустить сервер: %s" % error_string(error))
        return error
    multiplayer.multiplayer_peer = peer
    is_server = true
    connected = true
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    status_changed.emit("Сервер запущен. Порт: %d. Лимит: %d" % [port, MAX_PLAYERS])
    return OK

func join(address: String, port: int = DEFAULT_PORT) -> Error:
    peer = ENetMultiplayerPeer.new()
    var error := peer.create_client(address, port)
    if error != OK:
        status_changed.emit("Не удалось подключиться: %s" % error_string(error))
        return error
    multiplayer.multiplayer_peer = peer
    is_server = false
    status_changed.emit("Подключение к %s:%d..." % [address, port])
    return OK

func disconnect_session() -> void:
    multiplayer.multiplayer_peer = null
    peer = null
    is_server = false
    connected = false
    status_changed.emit("Отключено")

func _on_peer_connected(id: int) -> void:
    player_joined.emit(id)
    status_changed.emit("Игрок подключился: %d" % id)

func _on_peer_disconnected(id: int) -> void:
    player_left.emit(id)
    status_changed.emit("Игрок отключился: %d" % id)
