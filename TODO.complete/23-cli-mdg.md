# TODO.complete/23: `ea mdg` command

## Status: open

Expose the MDG technology registry via CLI.

## Plan

```
ea mdg list                       # list registered technologies
ea mdg show FeatureType           # stereotype details + tagged values
ea mdg show --tech GML            # all stereotypes in GML technology
ea mdg import custom.mdg.xml      # register custom technology
```

## Dependencies

- TODO.complete/10 (MDG registry).

## Acceptance

- Spec: `ea mdg list` includes CityGML and ISO 19103.
- Spec: `ea mdg show FeatureType` returns stereotype definition.
