"""
HealthDisplay.gd

A reusable UI component that displays health bars above entities.
This component automatically follows its parent's position and shows current HP.
"""
extends Control
class_name HealthDisplay

@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var health_label: Label = $VBoxContainer/HealthLabel

var target_health: Health
var camera: Camera3D
var target_entity: Node3D  # The entity this health bar belongs to
var world_offset: Vector3 = Vector3(0, 3, 0)  # Offset above the entity
var active_damage_numbers: Array[Node] = []  # Track active damage numbers for cleanup


func setup(health_component: Health, main_camera: Camera3D, entity: Node3D = null):
  target_health = health_component
  camera = main_camera
  target_entity = entity if entity else health_component.get_parent()

  # Validate setup
  if not target_health:
    Logger.warn("UI", "HealthDisplay setup with null health component")
    return
  if not camera:
    Logger.warn("UI", "HealthDisplay setup with null camera")
    return
  if not target_entity:
    Logger.warn("UI", "HealthDisplay setup with null target entity")
    return

  # Connect to health signals
  target_health.damaged.connect(_on_health_damaged)
  target_health.died.connect(_on_health_died)
  _update_display()


func _process(_delta: float):
  if target_entity and camera and is_inside_tree():
    # Get position from entity (handle different node types)
    var entity_pos = target_entity.global_position

    # For MeshInstance3D, try to get the AABB for better positioning
    if target_entity is MeshInstance3D:
      var mesh_instance = target_entity as MeshInstance3D
      if mesh_instance.mesh:
        var aabb = mesh_instance.get_aabb()
        # Position above the top of the mesh
        entity_pos.y += aabb.size.y + 1.0
      else:
        entity_pos += world_offset
    else:
      # For other node types, check if they have a MeshInstance3D child
      var mesh_child = target_entity.get_node_or_null("MeshInstance3D")
      if mesh_child and mesh_child is MeshInstance3D:
        var mesh_instance = mesh_child as MeshInstance3D
        if mesh_instance.mesh:
          var aabb = mesh_instance.get_aabb()
          entity_pos.y += aabb.size.y + 1.0
        else:
          entity_pos += world_offset
      else:
        entity_pos += world_offset

    # Convert world position to screen position
    var screen_pos = camera.unproject_position(entity_pos)

    # Update position (include shake offset)
    global_position = screen_pos - size / 2

    # Hide if behind camera
    var is_behind = camera.is_position_behind(entity_pos)
    visible = not is_behind


func _update_display():
  if not target_health:
    return

  var max_hp = target_health.max_hitpoints
  var current_hp = target_health.hitpoints

  if health_bar:
    health_bar.max_value = max_hp
    health_bar.value = current_hp

  if health_label:
    health_label.text = str(current_hp) + "/" + str(max_hp)


func _on_health_damaged(amount: int, _hitpoints: int):
  _update_display()

  # Create floating damage number
  _show_damage_number(amount)


func _on_health_died():
  _update_display()

  # Clean up any active damage numbers
  for damage_number in active_damage_numbers:
    if is_instance_valid(damage_number):
      damage_number.queue_free()
  active_damage_numbers.clear()

  # Could add death animation here
  # For now, just hide after a delay
  await get_tree().create_timer(1.0).timeout
  queue_free()


func _show_damage_number(damage: int):
  # Create a floating damage number effect
  var damage_label = Label.new()
  damage_label.text = "-" + str(damage)
  damage_label.add_theme_color_override("font_color", Color.RED)
  damage_label.add_theme_font_size_override("font_size", 24)

  # Add to the same UI parent as this health display
  get_parent().add_child(damage_label)

  # Track this damage number for cleanup
  active_damage_numbers.append(damage_label)

  # Position near the health bar but offset
  damage_label.global_position = global_position + Vector2(20, -10)

  # Animate the damage number
  var tween = create_tween()
  tween.set_parallel(true)
  tween.tween_property(
    damage_label, "global_position", damage_label.global_position + Vector2(0, -50), 1.0
  )
  tween.tween_property(damage_label, "modulate:a", 0.0, 1.0)

  # Remove after animation and clean up from tracking array
  await tween.finished
  active_damage_numbers.erase(damage_label)
  damage_label.queue_free()
