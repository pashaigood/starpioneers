# Game Systems

**For Developers & Designers**

This section contains detailed technical documentation for the core game systems and mechanics of Star Pioneers.

> **Note:** This is technical documentation. If you're here to understand the world and story, start with [The Universe](../1-universe/) or [Characters](../3-characters/) instead.

---

## Core Systems

### [Combat](./combat/)
Real-time space combat mechanics, targeting systems, damage models, and encounter design.

- `combat_design.md` - Core combat mechanics
- `combat_design_dark_souls.md` - Timing-based combat layer
- `combat_design_targeted.md` - Target-based combat approach

### [Economy](./economy/)
Planetary markets, resource trading, supply/demand simulation, and pricing.

- `planetary_economy.md` - Market systems and cargo mechanics

### [Pilots & AI](./pilots/)
Pilot behavior, decision-making architecture, needs/goals planning, and NPC simulation.

- `pilots.md` - Pilot characteristics and behavior
- `pilot_to_pirate.md` - Piracy progression mechanics
- `needs_and_goals_architecture.md` - AI planning system
- `PILOT_DECISION_ARCHITECTURE.md` - Decision-making framework
- `README_NEEDS_AND_GOALS.md` - System overview
- `SUMMARY_NEEDS_AND_GOALS.md` - Quick reference

### [Quests](./quests/)
Quest generation, director system, hooks, and narrative branching.

- `quest_system.md` - Complete quest architecture

### [Simulation](./simulation/)
World simulation, celestial mechanics, time systems, and entity management.

- `README_GenericSimulation.md` - Generic simulation framework
- `stellar_simulation.md` - Star system simulation

### [Planets](./planets/)
Planet generation, UI interactions, and player-planet mechanics.

- `planets.md` - Planet data and mechanics
- `planet_ui_and_interactions.md` - UI integration
- `planet_ui_layout.md` - Layout specifications
- `planetary-system-plan.md` - System architecture

### [Factions](./factions/)
Faction reputation systems, wanted mechanics, and political relationships.

- `faction_system.md` - Reputation and faction mechanics

### [General Systems](./general/)
Cross-cutting systems and integration guides.

- `time_and_calendar_design.md` - Game time and calendar
- `summary.md` - Systems overview
- `INTEGRATION_GUIDE.md` - Integration guidelines

---

## Design Philosophy

Star Pioneers uses an **emergent narrative** approach where player choices and simulated world events create unique stories. Core design principles:

1. **Player Agency** - Significant choices with meaningful consequences
2. **Simulation Depth** - NPCs and factions act independently with their own goals
3. **No Hand-Holding** - Players discover systems and consequences organically
4. **Moral Complexity** - Few purely good or evil choices
5. **Systems Interaction** - Combat, economy, reputation, and narrative interweave

---

## For Game Designers

If you're designing content (missions, encounters, faction behaviors), focus on:
- **Quest System** - How to create branching narratives
- **Faction System** - Reputation and consequence modeling
- **Economy** - Balancing risk/reward for player choices

## For Programmers

If you're implementing systems, key documents:
- **Simulation** - Core architecture
- **Pilots/AI** - Behavior tree and planning system
- **Integration Guide** - How systems connect

---

*This documentation assumes familiarity with Unity, C#, and game systems architecture.*

