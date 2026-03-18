# Adding a New Setting

Settings are wired up using `SettingBinding` scene nodes — no per-setting code is needed in `settings_menu.gd`. Follow these steps.

## Step 1 — Add the property to SettingsManager

Open `Utilities/Systems/settings_manager.gd` and add:

**a) A var with a sensible default:**
```gdscript
var show_damage_numbers: bool = true
```

**b) A load line inside `load_settings()`:**
```gdscript
show_damage_numbers = config.get_value("gameplay", "show_damage_numbers", show_damage_numbers)
```

**c) A save line inside `save_settings()`:**
```gdscript
config.set_value("gameplay", "show_damage_numbers", show_damage_numbers)
```

**d) (Optional) A typed setter if the setting needs side-effects:**
```gdscript
func set_show_damage_numbers(enabled: bool) -> void:
  show_damage_numbers = enabled
  save_settings()
```
`SettingBinding` uses `SettingsManager.set(key, value)` generically, so a plain var is enough when no side-effects are needed.

---

## Step 2 — Add the UI control to settings_menu.tscn

Open `Common/UI/settings_menu/settings_menu.tscn` in the Godot editor. Find the appropriate tab (Video / Audio / Twitch / Debug) and add:

**a)** A container node (usually `HBoxContainer`) to hold the label and control — e.g. `ShowDamageNumbersContainer`.

**b)** A `Label` child describing the setting — e.g. `text = "Show Damage Numbers"`.

**c)** The UI control. Supported types and their `control_property` values:

| Control type | `control_property` |
|---|---|
| `CheckButton` / `CheckBox` | `&"button_pressed"` |
| `HSlider` / `VSlider` | `&"value"` |
| `OptionButton` | `&"selected"` |
| `TextEdit` | `&"text"` |

---

## Step 3 — Add a SettingBinding child node

Inside the same container, add a `SettingBinding` node, then configure its exported properties in the Inspector:

| Property | Value | Notes |
|---|---|---|
| `setting_key` | `&"show_damage_numbers"` | Must match the var name in SettingsManager |
| `control_path` | `NodePath("../ShowDamageNumbersCheck")` | Relative to the SettingBinding node |
| `control_property` | `&"button_pressed"` | See table above |
| `apply_group` | `"gameplay"` | See Step 4 if adding a new group |
| `live_preview` | `false` | `true` = apply on every change; `false` = apply only on OK |
| `revert_on_cancel` | `true` | `false` only for runtime-only settings (e.g. debug mode) |

**That's it** — no changes to `settings_menu.gd` are needed. The menu discovers all `SettingBinding` descendants automatically.

---

## Step 4 — Adding a new apply_group (only if needed)

`apply_group` controls when `apply_value()` is called in bulk. Existing groups: `"video"`, `"audio"`, `"twitch"`, `"debug"`, `"none"`.

If your setting fits an existing group, just use it. To add a new group (e.g. `"gameplay"`):

1. Add it to the `@export_enum` in `SettingBinding.gd`:
   ```gdscript
   @export_enum("video", "audio", "twitch", "debug", "gameplay", "none") var apply_group
   ```
2. Handle it in `settings_menu.gd`'s `_on_apply_pressed()` alongside the existing groups.

---

## Step 5 — Reacting to changes (optional)

If you need side-effects when the user changes the value (e.g. updating other UI elements), connect to `value_changed` from `settings_menu.gd`:

In `_connect_binding_signals()`:
```gdscript
elif binding.setting_key == &"show_damage_numbers":
  binding.value_changed.connect(_on_show_damage_numbers_changed)
```

Add the handler:
```gdscript
func _on_show_damage_numbers_changed(value: Variant) -> void:
  # SettingsManager is already updated at this point
  pass
```

> **Note:** `value_changed` is emitted *after* `SettingsManager` has been updated (when `live_preview` is true), so it is always safe to read `SettingsManager` inside the handler.
