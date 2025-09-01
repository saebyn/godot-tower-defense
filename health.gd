extends Node
class_name Health

@export var hitpoints: int = 100
var dead: bool = false

signal died
signal damaged(amount: int, hitpoints: int)

func take_damage(amount: int):
  hitpoints -= amount
  damaged.emit(amount, hitpoints)
  if hitpoints <= 0:
    die()


func die():
  if dead:
    return
  dead = true
  died.emit()