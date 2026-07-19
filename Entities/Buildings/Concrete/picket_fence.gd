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

@export var left_enabled: bool:
  set(value):
    if Engine.is_editor_hint():
      crosspiece_left.visible = value
      picket_left.visible = value
      collision_left.disabled = not value
    else:
      ready.connect(func lambda():
        crosspiece_left.visible = value
        picket_left.visible = value
        collision_left.disabled = not value
      )
  get:
    return not collision_left.disabled
@export var right_enabled: bool:
  set(value):
    if Engine.is_editor_hint():
      crosspiece_right.visible = value
      picket_right.visible = value
      collision_right.disabled = not value
    else:
      ready.connect(func lambda():
        crosspiece_right.visible = value
        picket_right.visible = value
        collision_right.disabled = not value
      )
  get:
    return not collision_right.disabled
@export var post_enabled: bool:
  set(value):
    if Engine.is_editor_hint():
      post.visible = value
    else:
      ready.connect(func lambda():
        post.visible = value
      )
  get:
    return post.visible

