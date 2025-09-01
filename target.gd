extends MeshInstance3D

func _on_died():
  print("Enemy has died.")
  queue_free() # Remove the enemy from the scene when it dies.


func _on_health_damaged(amount: int, hitpoints: int) -> void:
  print("Enemy took ", amount, " damage. Remaining HP: ", hitpoints)
