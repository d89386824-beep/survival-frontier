extends CharacterBody3D

@export var move_speed := 5.5
@export var sprint_speed := 8.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.002
@export var max_health := 100.0
@export var max_hunger := 100.0
@export var max_thirst := 100.0

var health := 100.0
var hunger := 100.0
var thirst := 100.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_local_player := true

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
    add_to_group("players")
    if is_local_player:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if not is_local_player:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        head.rotate_x(-event.relative.y * mouse_sensitivity)
        head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    if not is_local_player:
        return
    if not is_on_floor():
        velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    var speed := sprint_speed if Input.is_action_pressed("sprint") else move_speed
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed)
        velocity.z = move_toward(velocity.z, 0.0, speed)
    move_and_slide()

    hunger = maxf(0.0, hunger - delta * 0.035)
    thirst = maxf(0.0, thirst - delta * 0.06)
    if hunger <= 0.0 or thirst <= 0.0:
        health = maxf(0.0, health - delta * 1.5)

func gather(kind: String, amount: int) -> void:
    Inventory.add_item(kind, amount)

func get_status() -> Dictionary:
    return {"health": health, "hunger": hunger, "thirst": thirst}
