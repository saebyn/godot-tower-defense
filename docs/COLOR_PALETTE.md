# Zom Nom Defense - Color Palette

This document defines the color palette extracted from the game logo and used throughout the UI theme.

## Primary Colors

### Orange (Primary Accent)
- **Hex**: `#F2A75A`
- **RGB**: `(242, 167, 90)`
- **Godot**: `Color(0.949, 0.655, 0.353, 1)`
- **Usage**: Title text, button hover states, button pressed borders, panel borders, focus states

### Cream/Beige (Text)
- **Hex**: `#EBD9BC`
- **RGB**: `(235, 217, 188)`
- **Godot**: `Color(0.922, 0.851, 0.737, 1)`
- **Usage**: Primary text color, button text, labels, hover borders

### Dark Teal (Background)
- **Hex**: `#2C4A4E`
- **RGB**: `(44, 74, 78)`
- **Godot**: `Color(0.172, 0.29, 0.306, 1)`
- **Usage**: Background color, panel backgrounds, disabled button backgrounds

### Zombie Green (Buttons)
- **Hex**: `#6B8C5E`
- **RGB**: `(107, 140, 94)`
- **Godot**: `Color(0.42, 0.549, 0.369, 1)`
- **Usage**: Normal button background, interactive elements

### Darker Green (Pressed State)
- **Hex**: `#5A7A4D`
- **RGB**: `(90, 122, 77)`
- **Godot**: `Color(0.353, 0.478, 0.302, 1)`
- **Usage**: Button pressed state background

### Dark Navy (Outlines & Shadows)
- **Hex**: `#1A1F2E`
- **RGB**: `(26, 31, 46)`
- **Godot**: `Color(0.102, 0.122, 0.18, 1)`
- **Usage**: Button borders, text shadows, outlines

## Color Usage by UI Element

### Buttons
- **Normal**: Zombie Green background, Dark Navy border, Cream text
- **Hover**: Orange background, Cream border, Cream text
- **Pressed**: Darker Green background, Orange border, Orange text
- **Disabled**: Dark Teal background (50% opacity), Dark Navy border (50% opacity), Cream text (50% opacity)

### Panels
- **Background**: Dark Teal (90% opacity)
- **Border**: Orange

### Text
- **Primary**: Cream/Beige
- **Shadow**: Dark Navy (80% opacity)
- **Focus/Accent**: Orange

## Theme Files
- **Main UI Theme**: `Config/ztd_ui_theme.tres`
- **HUD Theme**: `Config/ztd_hud_theme.tres`
- **Color Palette Resource**: `Config/ztd_color_palette.tres`

## Design Notes
The color scheme is inspired by the game's logo featuring:
- Bold orange lettering reminiscent of vintage action/horror fonts
- Zombie green elements representing the undead threat
- Dark teal creating a moody, post-apocalyptic atmosphere
- Cream text for excellent readability against dark backgrounds
