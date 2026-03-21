class_name HotbarButton
extends Button

@onready var slot_label := $SlotLabel
@onready var cost_label := $CostLabel


## Load the building data into the button
func load(slot_index: int, building: Resource_BuildingType) -> void:
  if building:
    # Set button icon and tooltip
    self.icon = building.icon if building.icon else null
    self.tooltip_text = "%s\nCost: %d\n%s\n\nLeft click: Select\nRight click: Choose different building" % [building.name, building.cost, building.description]
    self.disabled = false
    
    # Show cost and slot number on button
    slot_label.text = "%d" % (slot_index + 1)
    cost_label.text = "$%d" % building.cost
  else:
    # Empty slot
    self.icon = null
    self.tooltip_text = "Empty slot %d\n\nRight click to choose a building" % (slot_index + 1)
    self.disabled = true
    slot_label.text = "%d" % (slot_index + 1)
    cost_label.text = ""
