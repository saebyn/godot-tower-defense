extends MeshInstance3D

@onready var health: Health = $Health

func _ready():
  # Connect health signals
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)

func _on_died():
  print("Target has died.")
  queue_free() # Remove the target from the scene when it dies.


func _on_health_damaged(amount: float, hitpoints: int) -> void:
  print("Target took ", amount, " damage. Remaining HP: ", hitpoints)
