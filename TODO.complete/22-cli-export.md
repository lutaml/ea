# TODO.complete/22: `ea export` command

## Status: done

Single command for all model exports.

## Plan

```
ea export xmi model.qea -o model.xmi        # XMI export (current `convert`)
ea export json model.qea                    # JSON model
ea export plantuml model.qea --package core # PlantUML for docs
ea export xsd model.qea --stereo FeatureType  # XSD (depends on TODO.complete/11)
```

## Migration

- `ea convert` becomes alias for `ea export xmi`.
- New subcommands: `json`, `plantuml`, `xsd`.

## OCP / MECE

- One exporter per format, registered in `ExportRegistry`.
- New format = new exporter class.

## Acceptance

- Spec: `ea export xmi` round-trips a model (parse → export → re-parse).
- Spec: `ea export json` produces valid JSON with all top-level entities.
