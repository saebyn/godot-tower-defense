@tool
extends GraphEdit

## OrthogonalGraphEdit
## GraphEdit subclass that draws connections as orthogonal (right-angle) lines
## instead of the default bezier curves.

func _get_connection_line(from_position: Vector2, to_position: Vector2) -> PackedVector2Array:
  # Draw an orthogonal path: horizontal mid-point then vertical then horizontal
  # from_position is the right port of the source node
  # to_position is the left port of the destination node
  var mid_x := (from_position.x + to_position.x) * 0.5
  return PackedVector2Array([
    from_position,
    Vector2(mid_x, from_position.y),
    Vector2(mid_x, to_position.y),
    to_position,
  ])
