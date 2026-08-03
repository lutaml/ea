# TODO-D 52: Marker registration architecture + Plus marker

## Problem

The original `marker.rb` had eager registration:

```ruby
Registry.register(Diamond)
Registry.register(OpenTriangle)
Registry.register(Plus)
Registry.register(ArrowPath)
```

But Diamond, OpenTriangle, etc. were declared via `autoload`, so
the constant lookup at module load time failed with:

```
NameError: uninitialized constant Ea::Svg::EaEmitter::Marker::Plus
```

## Solution

Two-part lazy registration:

1. **Self-registration at file scope**: each marker kind file
   (diamond.rb, open_triangle.rb, plus.rb, arrow_path.rb) ends
   with a fully-qualified registration call:

   ```ruby
   Ea::Svg::EaEmitter::Marker::Registry.register(
     Ea::Svg::EaEmitter::Marker::Plus
   )
   ```

   This runs when the file loads (which happens via autoload when
   the constant is first referenced).

2. **Lazy autoload trigger**: `Marker.ensure_builtins_registered!`
   references each autoloaded marker constant, which triggers
   file load, which runs the per-file registration line.

   ```ruby
   def self.ensure_builtins_registered!
     Diamond
     OpenTriangle
     Plus
     ArrowPath
   end
   ```

3. **First-use hook**: `Registry.specs_for` calls
   `Marker.ensure_builtins_registered!` before searching kinds,
   so registration is triggered on the first marker lookup.

## Benefits

- **OCP**: Adding a new marker kind = creating a new file with
  its class + registration line. The marker.rb dispatcher does
  NOT need modification.
- **Lazy loading**: marker kinds only load when the registry is
  first queried.
- **No autoload cycle**: each kind file knows its own constant;
  registration at the bottom of the file is safe.

## Plus marker addition

New `Marker::Plus` for Nesting connectors. EA renders a 16x16
plus symbol at the contained end:

```
M cx cy-8 L cx cy+8    (vertical arm)
M cx+8 cy L cx-8 cy    (horizontal arm)
```

basic.qea 'Package Contents' (3 visible nesting connectors) →
100% path parity.

## Tests

- spec/ea/svg/ea_emitter/marker/plus_spec.rb (5 specs):
  handles? for Nesting, specs_for shape/anchor, ARM_LENGTH
  constant.

## Verification

- 1764 specs pass (up from 1759, +5 new)
- basic.qea: 20/22 diagrams within tolerance (was 19/22)
- Plateau bench unchanged: rect -221, path -280, polygon -6,
  text -627.
