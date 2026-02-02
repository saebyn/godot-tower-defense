extends Node

## Maximum number of damage numbers in the pool
const MAX_POOL_SIZE: int = 10
## Font size for numbers
const FONT_SIZE: int = 32


# Pool of damage number Label3D nodes
var _number_pool: Array[Label3D] = []
# Track active tweens for cleanup
var _active_tweens: Dictionary[Label3D, Tween] = {}


## Register a tween for a label to track its lifecycle
func add_tween(label: Label3D, tween: Tween) -> void:
  _active_tweens[label] = tween
  tween.finished.connect(_on_tween_finished.bind(label))

## Get an available label from pool or create a new one
func get_or_create_label() -> Label3D:
  # Try to find an inactive label in the pool
  for label in _number_pool:
    if not is_instance_valid(label):
      continue
    if not label.visible:
      return label
  
  # Create new if pool not full
  if _number_pool.size() < MAX_POOL_SIZE:
    var new_label = _create_label()
    if new_label == null:
      # Failed to create label (likely headless mode)
      return null
    _number_pool.append(new_label)
    return new_label
  
  # Pool full - recycle an existing label
  if not _number_pool.is_empty():
    # Find any label and force-deactivate it for reuse
    for label in _number_pool:
      if not is_instance_valid(label):
        continue
      # Kill the tween if active
      if _active_tweens.has(label) and is_instance_valid(_active_tweens[label]):
        _active_tweens[label].kill()
        _active_tweens.erase(label)
      _deactivate_number(label)
      return label
  
  return null


## Create a new Label3D with the correct settings
func _create_label() -> Label3D:
  # Check if current_scene is available before creating the label
  # In headless mode or when no scene is loaded, current_scene is null
  var current_scene = get_tree().current_scene
  if current_scene == null:
    return null
  
  var label = Label3D.new()
  
  # Add to scene tree (at current scene level)
  current_scene.add_child(label)
  
  # Configure label appearance
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  label.no_depth_test = true
  label.modulate = Color.WHITE
  label.outline_size = 8
  label.outline_modulate = Color.BLACK
  label.font_size = FONT_SIZE
  
  # Use fixed_size so it's visible regardless of zoom level
  label.fixed_size = true
  
  # Start invisible
  label.visible = false
  
  return label


## Deactivate a label and return it to the pool
func _deactivate_number(label: Label3D):
  label.visible = false
  label.font_size = FONT_SIZE # Reset font size


## Called when a tween animation finishes
func _on_tween_finished(label: Label3D):
  _deactivate_number(label)
  if _active_tweens.has(label):
    _active_tweens.erase(label)