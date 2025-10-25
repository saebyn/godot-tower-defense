extends Control
class_name FpsOverlay

## UI component to display FPS and performance statistics
## Shows real-time performance metrics in a compact overlay

@onready var fps_label: Label = $FpsLabel

# Performance tracking
var frame_times: Array[float] = []
const MAX_FRAME_SAMPLES = 60

func _ready():
  # Start hidden by default
  visible = false
  
  # Ensure we're always on top
  z_index = 100

func _process(_delta: float) -> void:
  if not visible:
    return
  
  # Update FPS and performance stats
  _update_display()

func _update_display() -> void:
  if not fps_label:
    return
  
  # Get current FPS
  var fps = Engine.get_frames_per_second()
  
  # Get frame time in milliseconds
  var frame_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
  
  # Get memory usage in MB
  var static_memory = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
  var total_memory = static_memory
  
  # Get object/node counts
  var object_count = Performance.get_monitor(Performance.OBJECT_COUNT)
  var node_count = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
  
  # Build display text
  var text = ""
  text += "FPS: %d\n" % fps
  text += "Frame Time: %.2f ms\n" % frame_time
  text += "Memory: %.1f MB\n" % total_memory
  text += "Objects: %d\n" % object_count
  text += "Nodes: %d" % node_count
  
  fps_label.text = text

## Toggle visibility of FPS overlay
func toggle_visibility() -> void:
  visible = not visible
  Logger.info("FpsOverlay", "FPS overlay toggled: %s" % ("visible" if visible else "hidden"))
