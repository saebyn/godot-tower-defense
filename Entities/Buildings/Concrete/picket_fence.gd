@tool
extends Entity_Building
class_name Entity_PicketFence

@onready var post: MeshInstance3D = $Fence/Post
@onready var crosspiece_left: MeshInstance3D = $Fence/Crosspiece_Left
@onready var crosspiece_right: MeshInstance3D = $Fence/Crosspiece_Right
@onready var picket_left: MeshInstance3D = $Fence/Picket_Left
@onready var picket_right: MeshInstance3D = $Fence/Picket_Right
@onready var collision_left: CollisionShape3D = $CollisionShape3D_Left
@onready var collision_right: CollisionShape3D = $CollisionShape3D_Right

var _left_enabled: bool = true
var _right_enabled: bool = true
var _post_enabled: bool = true

@export var left_enabled: bool:
  set(value):
    _left_enabled = value
    _sync_states()
  get:
    return _left_enabled
@export var right_enabled: bool:
  set(value):
    _right_enabled = value
    _sync_states()
  get:
    return _right_enabled
@export var post_enabled: bool:
  set(value):
    _post_enabled = value
    _sync_states()
  get:
    return _post_enabled


func _ready() -> void:
  super._ready()
  _sync_states()


func _sync_states() -> void:
  if crosspiece_left:
    crosspiece_left.visible = _left_enabled
  if picket_left:
    picket_left.visible = _left_enabled
  if collision_left:
    collision_left.disabled = not _left_enabled

  if crosspiece_right:
    crosspiece_right.visible = _right_enabled
  if picket_right:
    picket_right.visible = _right_enabled
  if collision_right:
    collision_right.disabled = not _right_enabled

  if post:
    post.visible = _post_enabled
