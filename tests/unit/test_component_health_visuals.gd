extends GutTest

## Unit tests for Component_Health visual improvements:
## - Dynamic transparency based on HP ratio
## - Entity-type-based bar color selection

# Helper: create a health instance attached to a parent node
func _make_health(parent: Node = null) -> Component_Health:
  if not parent:
    parent = Node3D.new()
  var health_scene = load("res://Common/Components/health/health.tscn")
  var health: Component_Health = health_scene.instantiate()
  parent.add_child(health)
  add_child_autofree(parent)
  return health


# ────────────────────────────────────────────────────────────────
# Transparency tests
# ────────────────────────────────────────────────────────────────

func test_full_health_fades_to_high_opacity():
  var health := _make_health()
  await get_tree().process_frame

  # At 100% HP sprite should be faded
  assert_almost_eq(health.sprite.modulate.a, Component_Health.HIGH_HP_OPACITY, 0.01,
    "Full HP should use HIGH_HP_OPACITY")

func test_low_health_shows_full_opacity():
  var health := _make_health()
  await get_tree().process_frame

  # Drop HP well below threshold (e.g., 10% HP)
  health.hitpoints = int(health.max_hitpoints * 0.1)
  health._update_display()

  assert_almost_eq(health.sprite.modulate.a, Component_Health.FULL_OPACITY, 0.01,
    "Very low HP should approach FULL_OPACITY")

func test_opacity_interpolates_at_threshold_boundary():
  var health := _make_health()
  await get_tree().process_frame

  # Exactly at threshold (80%)
  health.hitpoints = int(health.max_hitpoints * Component_Health.HIGH_HP_THRESHOLD)
  health._update_display()

  # Should be at HIGH_HP_OPACITY (just at/above threshold)
  assert_almost_eq(health.sprite.modulate.a, Component_Health.HIGH_HP_OPACITY, 0.05,
    "HP at threshold should be near HIGH_HP_OPACITY")

func test_label_opacity_never_below_minimum():
  var health := _make_health()
  await get_tree().process_frame

  # At full health the label should still be at least 60% opaque
  assert_gte(health.health_label.modulate.a, 0.6,
    "Label opacity should never drop below 0.6")

func test_label_opacity_at_low_health():
  var health := _make_health()
  await get_tree().process_frame

  health.hitpoints = 1
  health._update_display()

  assert_gte(health.health_label.modulate.a, 0.6,
    "Label opacity should remain readable at low HP")


# ────────────────────────────────────────────────────────────────
# Bar color tests
# ────────────────────────────────────────────────────────────────

func test_default_color_when_no_parent_type():
  var health := _make_health()
  await get_tree().process_frame

  # Plain Node3D parent has no enemy_type — should use DEFAULT color
  var color := health._get_effective_bar_color()
  assert_eq(color, Component_Health.COLOR_DEFAULT,
    "No-type parent should yield COLOR_DEFAULT")

func test_fast_enemy_type_yields_fast_color():
  # enemy_type strings are runtime identifiers set via Resource_EnemyType.enemy_type
  # (Config/Enemies/enemy_type_resource.gd). "fast" substring triggers fast-zombie coloring.
  var parent = Node3D.new()
  parent.set("enemy_type", "zombie_fast")
  var health := _make_health(parent)
  await get_tree().process_frame

  var color := health._get_effective_bar_color()
  assert_eq(color, Component_Health.COLOR_ZOMBIE_FAST,
    "fast enemy_type should yield COLOR_ZOMBIE_FAST")

func test_tank_enemy_type_yields_tank_color():
  # "tank" substring triggers tank-zombie coloring.
  var parent = Node3D.new()
  parent.set("enemy_type", "zombie_tank")
  var health := _make_health(parent)
  await get_tree().process_frame

  var color := health._get_effective_bar_color()
  assert_eq(color, Component_Health.COLOR_ZOMBIE_TANK,
    "tank enemy_type should yield COLOR_ZOMBIE_TANK")

func test_standard_enemy_type_yields_standard_color():
  # Any enemy_type without "fast"/"tank" falls through to standard zombie coloring.
  var parent = Node3D.new()
  parent.set("enemy_type", "base_enemy")
  var health := _make_health(parent)
  await get_tree().process_frame

  var color := health._get_effective_bar_color()
  assert_eq(color, Component_Health.COLOR_ZOMBIE_STANDARD,
    "base enemy_type should yield COLOR_ZOMBIE_STANDARD")

func test_survivor_group_yields_survivor_color():
  var parent = Node3D.new()
  add_child_autofree(parent)
  parent.add_to_group("survivors")
  var health_scene = load("res://Common/Components/health/health.tscn")
  var health: Component_Health = health_scene.instantiate()
  parent.add_child(health)
  await get_tree().process_frame

  var color := health._get_effective_bar_color()
  assert_eq(color, Component_Health.COLOR_SURVIVOR,
    "survivor group should yield COLOR_SURVIVOR")

func test_explicit_bar_color_overrides_auto():
  var health := _make_health()
  health.use_custom_bar_color = true
  health.bar_color = Color(1.0, 0.0, 0.0, 1.0)  # bright red override
  await get_tree().process_frame

  var color := health._get_effective_bar_color()
  assert_eq(color, Color(1.0, 0.0, 0.0, 1.0),
    "Explicit bar_color should override auto-detection")
