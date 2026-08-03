# TODO.complete/32: Specs for new code paths

## Status: done

New code added in Streams A/B/C must have specs. This file is the
tracking list — each completed TODO contributes specs.

## Required specs

| TODO | Spec path | Coverage |
|---|---|---|
| 01 t_xref | spec/ea/sources/qea/xref_parser_spec.rb | parse all 3 block types |
| 02 per-label geometry | spec/ea/sources/qea/geometry_parser_spec.rb | parse label slot styling |
| 03 props/constraints | spec/ea/sources/qea/classifier_builder_spec.rb | attach to classifier |
| 04 operation params | spec/ea/sources/qea/operation_builder_spec.rb | parameter list |
| 05 PDATA flags | spec/ea/sources/qea/pdata_flags_spec.rb | all flags |
| 06 EMF image | spec/ea/image/emf_renderer_spec.rb | convert blob |
| 10 MDG registry | spec/ea/mdg/registry_spec.rb | lookups |
| 11 GML XSD | spec/ea/export/xsd/generator_spec.rb | schema gen |
| 20 diff CLI | spec/ea/cli/diff_spec.rb | added/removed/modified |
| 30 HeaderLines | spec/ea/svg/ea_emitter/element/header_line_pipeline_spec.rb | provider chain |

## Standards

- No doubles (`double()`). Use real model instances or `Struct.new`.
- Test behavior, not implementation.
- One spec file per concern.

## Acceptance

- All new code has corresponding spec file.
- `bundle exec rspec` passes with 0 failures.
- Code coverage on new files > 90%.
