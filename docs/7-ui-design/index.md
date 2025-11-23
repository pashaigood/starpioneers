# UI Design

**Interface Specifications & Component Architecture**

This section contains detailed UI/UX design documentation for Star Pioneers interface systems.

---

## Planet Card Interface

The Planet Card is the primary interface for planet-side interactions—refueling, repairs, trading, missions, and takeoff.

### Documentation

- **[UI Components](./planet-card/ui_components.md)** - Detailed component specifications
- **[Architecture](./planet-card/architecture.md)** - System architecture and data flow
- **[Data Flow](./planet-card/data_flow.md)** - How data moves through the UI
- **[USS/UXML Specification](./planet-card/uss_uxml_specification.md)** - Unity UI Toolkit implementation

### Design Principles

**Lore Integration**  
The interface reflects the in-universe aesthetic: functional, space-faring equipment with worn textures and practical layouts.

**Immediate Feedback**  
Every player action results in immediate visual or audio feedback. No silent failures.

**Contextual Information**  
UI elements display relevant information without cluttering the screen. Tooltips and progressive disclosure keep the interface clean.

**Accessibility**  
Full keyboard navigation, screen reader support, high-contrast mode, and reduced motion options.

---

## Other UI Systems

*(Coming soon)*

- **Space Navigation UI** - Jump planning, route visualization
- **Combat HUD** - Targeting, damage indicators, tactical displays
- **Inventory & Cargo** - Ship management interface
- **Dialogue System** - Conversation UI and choice presentation
- **Map & Navigation** - System map, waypoints, faction territories

---

## Visual Style Guide

**Color Palette:**
- Primary: Deep space blues
- Accents: Cyan highlights (jump tech aesthetic)
- Warning: Amber/Orange
- Danger: Red
- Success: Green

**Typography:**
- Headers: Bold, clear sans-serif
- Body: Readable monospaced for data
- UI Labels: Uppercase, condensed

**Spacing & Layout:**
- 8px grid system
- Generous padding for touch/click targets
- Minimize nesting depth

---

## Implementation Notes

All UI is built using **Unity UI Toolkit** (formerly UIElements):
- UXML for structure
- USS for styling
- C# controllers for logic

This allows for:
- Responsive layouts
- Runtime theme switching
- Easy localization
- Performance optimization

---

*For technical implementation details, see individual component specifications.*

