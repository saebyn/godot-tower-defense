extends Node
class_name Health

@export var hitpoints: float = 100.0

signal died
signal damaged(amount: float, hitpoints: int)

func take_damage(amount: float):
  hitpoints -= amount
  damaged.emit(amount, hitpoints)
  if hitpoints <= 0:
    die()


func die():
  print("Entity has died.")
  died.emit()