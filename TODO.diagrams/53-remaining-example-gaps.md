# TODO-D 53: Remaining example parity gaps (deferred)

## Summary

This round achieved 15/27 → 17/27 example diagrams at 100% parity
(plus 2/2 simple + 1/2 test, 20/22 basic, 5/6 ArcGIS).

```
simple              2/2   matched    100% ✓
ArcGISWorkspace     5/6   matched
basic              20/22  matched
test                1/2   matched
```

## Remaining basic.qea gaps (7 diagrams, all minor)

| Diagram | rect | path | polygon | text | Root cause |
|---------|------|------|---------|------|------------|
| Package Imports | -6 | -18 | 0 | -4 | visibility icons missing |
| Object with Value Specifications | 0 | -6 | 0 | -19 | object instance format |
| Objects as Instances of Classes | 0 | -4 | 0 | -9 | object instance format |
| Domain Model | +3 | -7 | +1 | -8 | tree-routed bezier paths |
| Basic Object Diagram | 0 | -3 | 0 | -2 | (object value slots) |
| Basic Class with Receptions | 0 | +5 | -2 | -3 | extra compartment dividers |
| Composition with Substitution | 0 | 0 | 0 | -1 | nested class display_name |

## test.qea gap

`Test Model` diagram: r=-15, p=-58, po=0, t=-11. Needs visibility
icons + Package element attribute rendering.

## Implementation paths (in priority order)

### TODO-D 54: Visibility icons (TODO-D 51 expansion)

EA renders 5-6 element decorations per attribute row when
`ShowIcons=1`:
- 1 outer rect (11x14, pale yellow + blue stroke)
- 1 inner rect (11x4, white)
- 1 horizontal divider path (midline)
- 3-4 short "text line" paths inside

This closes `Test Model` (r=-15, p=-58) and `Package Imports`
(r=-6, p=-18). 73+ missing elements across examples.

Implementation: `Compartment::VisibilityIcon` + discriminator in
`RenderContext` (default hidden, opt-in via DiagramElement#icon_visible
or DisplayConfig#show_icons).

### TODO-D 55: Object instance format

EA renders object instances as:
- Header: `Object 01 / roleOne: Class A` (instance name + role + classifier)
- Slot rows: `attribute = value` for each slot
- Package qualifier: `(from Objects)`

Current code renders them as plain classes with the qualified class
name. Requires new `Ea::Model::InstanceSpecification` model + QEA
parser support + ObjectInstanceRenderer compartment.

### TODO-D 56: Tree-routed bezier paths

EA renders tree-routed connectors with cubic bezier curves
(C commands) for smooth paths. We render straight L segments.
The visual is similar but path count differs. Detection: when a
connector has 3+ waypoints with `tree:` style, emit bezier.

## Architectural decisions documented this round

1. **«property» label OY-gap rule**: real geometry check (15px
   threshold) instead of always-true.
2. **Implicit connector visibility**: render Nesting when
   `tree:` style is set, filter otherwise.
3. **Plus marker**: new `Marker::Plus` kind for Nesting connector
   "+" decoration (lazy registration architecture).
4. **Marker registration**: per-file `Registry.register(...)` +
   `Marker.ensure_builtins_registered!` — OCP-friendly, no
   autoload cycle.

## Final state

- 1764 specs pass
- Zero code-quality violations
- basic.qea: 8 → 9 perfect diagrams (out of 22)
- test.qea: 0 → 1 perfect diagram (out of 2)
- simple.qea: 2/2 perfect
