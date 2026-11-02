extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const InventoryScript := preload("res://scripts/inventory.gd")

var inventory: Node
var hud: CanvasLayer
var status_label: Label
var inventory_label: Label
var stats_label: Label
var player: CharacterBody3D

func _ready() -> void:
    _setup_input()
    inventory = InventoryScript.new()
    inventory.name = "Inventory"
    add_child(inventory)
    inventory.changed.connect(_refresh_inventory)
    _build_world()
    _build_hud()
    _spawn_local_player()
    NetworkManager.status_changed.connect(_set_status)
    _set_status("Одиночный прототип. Нажми F1 для запуска сервера, F2 для подключения.")

func _setup_input() -> void:
    _add_key_action("move_forward", KEY_W)
    _add_key_action("move_back", KEY_S)
    _add_key_action("move_left", KEY_A)
    _add_key_action("move_right", KEY_D)
    _add_key_action("jump", KEY_SPACE)
    _add_key_action("sprint", KEY_SHIFT)
    _add_key_action("interact", KEY_E)
    _add_key_action("server", KEY_F1)
    _add_key_action("connect", KEY_F2)

func _add_key_action(action: String, key: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = key
    InputMap.action_add_event(action, event)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("server"):
        NetworkManager.host()
    elif event.is_action_pressed("connect"):
        NetworkManager.join("127.0.0.1")
    elif event.is_action_pressed("interact"):
        _try_gather()

func _build_world() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.55, 0.62, 0.7)
    env.ambient_light_energy = 0.7
    environment.environment = env
    add_child(environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.2
    add_child(sun)

    _make_box("Ground", Vector3(0, -0.5, 0), Vector3(180, 1, 180), Color(0.22, 0.34, 0.19), true)
    # Test clearing and scattered resource nodes.
    for i in range(28):
        var x := randf_range(-75, 75)
        var z := randf_range(-75, 75)
        if Vector2(x, z).length() < 12.0:
            continue
        if i % 2 == 0:
            _make_tree(Vector3(x, 0, z))
        else:
            _make_rock(Vector3(x, 0, z))
    _make_box("Abandoned shed", Vector3(18, 1.5, -24), Vector3(8, 3, 7), Color(0.27, 0.25, 0.21), true)

func _make_box(label: String, pos: Vector3, size: Vector3, color: Color, solid: bool) -> Node3D:
    var body: Node3D
    if solid:
        body = StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        collision.position = Vector3(0, size.y / 2.0, 0)
        body.add_child(collision)
    else:
        body = Node3D.new()
    body.name = label
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh.material_override = material
    mesh.position.y = size.y / 2.0
    body.add_child(mesh)
    add_child(body)
    return body

func _make_tree(pos: Vector3) -> void:
    var tree := StaticBody3D.new()
    tree.position = pos
    tree.add_to_group("wood_nodes")
    var trunk := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.28
    cylinder.bottom_radius = 0.42
    cylinder.height = 3.2
    trunk.mesh = cylinder
    trunk.position.y = 1.6
    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color(0.28, 0.16, 0.09)
    trunk.material_override = bark
    tree.add_child(trunk)
    var crown := MeshInstance3D.new()
    var cone := ConeMesh.new()
    cone.radius = 1.55
    cone.height = 3.4
    crown.mesh = cone
    crown.position.y = 4.0
    var leaves := StandardMaterial3D.new()
    leaves.albedo_color = Color(0.08, 0.25, 0.12)
    crown.material_override = leaves
    tree.add_child(crown)
    var collision := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = 0.45
    shape.height = 3.2
    collision.shape = shape
    collision.position.y = 1.6
    tree.add_child(collision)
    add_child(tree)

func _make_rock(pos: Vector3) -> void:
    var rock := StaticBody3D.new()
    rock.position = pos
    rock.add_to_group("stone_nodes")
    var mesh := MeshInstance3D.new()
    var shape_mesh := SphereMesh.new()
    shape_mesh.radius = 0.9
    shape_mesh.height = 1.3
    mesh.mesh = shape_mesh
    mesh.position.y = 0.65
    mesh.scale = Vector3(1.3, 0.8, 1.1)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.37, 0.39, 0.4)
    mesh.material_override = mat
    rock.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 0.9
    collision.shape = shape
    collision.position.y = 0.65
    rock.add_child(collision)
    add_child(rock)

func _spawn_local_player() -> void:
    player = PLAYER_SCENE.instantiate()
    player.name = "LocalPlayer"
    player.position = Vector3(0, 2, 0)
    add_child(player)

func _build_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var panel := PanelContainer.new()
    panel.position = Vector2(18, 18)
    panel.custom_minimum_size = Vector2(310, 112)
    hud.add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    status_label = Label.new()
    status_label.text = "SURVIVAL: FRONTIER"
    column.add_child(status_label)
    stats_label = Label.new()
    stats_label.text = "Здоровье 100 | Голод 100 | Жажда 100"
    column.add_child(stats_label)
    inventory_label = Label.new()
    inventory_label.text = "Рюкзак: пусто"
    column.add_child(inventory_label)
    var help := Label.new()
    help.position = Vector2(18, 640)
    help.text = "WASD — движение · Shift — бег · Space — прыжок · E — добыча · F1 — сервер · F2 — подключение"
    hud.add_child(help)

func _process(_delta: float) -> void:
    if is_instance_valid(player):
        var s: Dictionary = player.get_status()
        stats_label.text = "Здоровье %.0f | Голод %.0f | Жажда %.0f" % [s.health, s.hunger, s.thirst]

func _try_gather() -> void:
    if not is_instance_valid(player):
        return
    var from := player.global_position + Vector3.UP * 1.4
    var to := from + -player.global_transform.basis.z * 4.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return
    var collider: Object = hit.collider
    if collider is Node and collider.is_in_group("wood_nodes"):
        inventory.add_item("Дерево", 5)
        collider.queue_free()
    elif collider is Node and collider.is_in_group("stone_nodes"):
        inventory.add_item("Камень", 4)
        collider.queue_free()

func _refresh_inventory(items: Dictionary) -> void:
    var parts: Array[String] = []
    for key in items:
        if int(items[key]) > 0:
            parts.append("%s: %d" % [key, items[key]])
    inventory_label.text = "Рюкзак: " + (", ".join(parts) if not parts.is_empty() else "пусто")

func _set_status(message: String) -> void:
    if is_instance_valid(status_label):
        status_label.text = "SURVIVAL: FRONTIER · " + message
