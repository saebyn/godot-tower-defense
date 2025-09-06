extends MeshInstance3D

func _on_died():
  print("Target has died.")
  queue_free() # Remove the target from the scene when it dies.


func _on_health_damaged(amount: int, hitpoints: int) -> void:
  print("Enemy took ", amount, " damage. Remaining HP: ", hitpoints)
