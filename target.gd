extends MeshInstance3D

@export var hitpoints: float = 100.0

func hit(amount: float):
  hitpoints -= amount
  print("Took", amount, "damage. Remaining hitpoints:", hitpoints)
  if hitpoints <= 0:
    die()


func die():
  print("Enemy has died.")
  queue_free() # Remove the enemy from the scene when it dies.
