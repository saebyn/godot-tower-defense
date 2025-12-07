class_name HotbarButton
extends Button

@onready var slot_label := $SlotLabel
@onready var cost_label := $CostLabel


## Load the obstacle data into the button
func load(slot_index: int, obstacle: Resource_ObstacleType) -> void:
  if obstacle:
    # Set button icon and tooltip
    self.icon = obstacle.icon if obstacle.icon else null
    self.tooltip_text = "%s\nCost: %d\n%s\n\nLeft click: Select\nRight click: Choose different obstacle" % [obstacle.name, obstacle.cost, obstacle.description]
    self.disabled = false
    
    # Show cost and slot number on button
    slot_label.text = "%d" % (slot_index + 1)
    cost_label.text = "$%d" % obstacle.cost
  else:
    # Empty slot
    self.icon = null
    self.tooltip_text = "Empty slot %d\n\nRight click to choose an obstacle" % (slot_index + 1)
    self.disabled = true
    slot_label.text = "%d" % (slot_index + 1)
    cost_label.text = ""
