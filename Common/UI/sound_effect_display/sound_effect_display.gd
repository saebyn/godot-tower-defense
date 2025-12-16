extends Control
class_name UI_SoundEffectDisplay

## Debug display showing recently played sound effects in screen corner
## Aggregates duplicate sounds with counts and auto-expires after 5 seconds

const EXPIRY_TIME = 5.0
const MAX_DISPLAYED_EFFECTS = 10

var container: VBoxContainer = null

# Dictionary to track sound effects: {effect_name: {count: int, timestamp: float, label: Label}}
var tracked_effects: Dictionary = {}

# Cache for enum value to name mapping (for performance)
var _effect_name_cache: Dictionary = {}

func _ready() -> void:
  # Try to get the container node if it exists
  if has_node("%EffectsContainer"):
    container = %EffectsContainer
  
  # Build enum name cache for fast lookups
  for key in Resource_SoundEffect.SoundEffect.keys():
    var value = Resource_SoundEffect.SoundEffect[key]
    # Transform enum key: replace underscores with spaces and capitalize each word
    var readable_name = key.replace("_", " ").capitalize()
    _effect_name_cache[value] = readable_name
  
  # Connect to AudioManager signal for sound played events
  if not AudioManager.sound_played.is_connected(_on_sound_played):
    AudioManager.sound_played.connect(_on_sound_played)
  
  # Hide by default - this is an optional debug feature
  visible = false
  
  MyLogger.info("SoundEffectDisplay", "Sound effect display initialized")

func _process(delta: float) -> void:
  if not visible:
    return
  
  # Check for expired effects and update display
  _cleanup_expired_effects()

## Handle sound effect played event
func _on_sound_played(effect: Resource_SoundEffect.SoundEffect) -> void:
  if not visible or not container:
    return
  
  var effect_name = _get_effect_name(effect)
  var current_time = Time.get_ticks_msec() / 1000.0
  
  if effect_name in tracked_effects:
    # Update existing entry
    var entry = tracked_effects[effect_name]
    entry.count += 1
    entry.timestamp = current_time
    _update_label(entry)
  else:
    # Create new entry
    var label = Label.new()
    label.add_theme_font_size_override("font_size", 14)
    container.add_child(label)
    
    var entry = {
      "count": 1,
      "timestamp": current_time,
      "label": label,
      "effect": effect
    }
    tracked_effects[effect_name] = entry
    _update_label(entry)
    
    # Limit number of displayed effects
    _enforce_max_display_limit()

## Update label text for an entry
func _update_label(entry: Dictionary) -> void:
  var effect_name = _get_effect_name(entry.effect)
  if entry.count > 1:
    entry.label.text = "%s (x%d)" % [effect_name, entry.count]
  else:
    entry.label.text = effect_name

## Remove expired effects (older than EXPIRY_TIME seconds)
func _cleanup_expired_effects() -> void:
  var current_time = Time.get_ticks_msec() / 1000.0
  var to_remove = []
  
  for effect_name in tracked_effects.keys():
    var entry = tracked_effects[effect_name]
    if current_time - entry.timestamp > EXPIRY_TIME:
      to_remove.append(effect_name)
  
  for effect_name in to_remove:
    var entry = tracked_effects[effect_name]
    if entry.label:
      entry.label.queue_free()
    tracked_effects.erase(effect_name)

## Remove oldest effects if we exceed max display limit
func _enforce_max_display_limit() -> void:
  # Keep removing oldest effects until we're under the limit
  while tracked_effects.size() > MAX_DISPLAYED_EFFECTS:
    # Find oldest entry
    var oldest_name = ""
    var oldest_time = INF
    
    for effect_name in tracked_effects.keys():
      var entry = tracked_effects[effect_name]
      if entry.timestamp < oldest_time:
        oldest_time = entry.timestamp
        oldest_name = effect_name
    
    if oldest_name != "":
      var entry = tracked_effects[oldest_name]
      if entry.label:
        entry.label.queue_free()
      tracked_effects.erase(oldest_name)
    else:
      # Safety break if we can't find an oldest entry
      break

## Get human-readable name for sound effect
func _get_effect_name(effect: Resource_SoundEffect.SoundEffect) -> String:
  # Use cached mapping for O(1) lookup instead of O(n) search
  if effect in _effect_name_cache:
    return _effect_name_cache[effect]
  return "Unknown"

## Toggle visibility of the display
func toggle_display() -> void:
  visible = !visible
  if not visible:
    _clear_all_effects()
  MyLogger.info("SoundEffectDisplay", "Display toggled: %s" % ("visible" if visible else "hidden"))

## Clear all tracked effects
func _clear_all_effects() -> void:
  for effect_name in tracked_effects.keys():
    var entry = tracked_effects[effect_name]
    if entry.label:
      entry.label.queue_free()
  tracked_effects.clear()
