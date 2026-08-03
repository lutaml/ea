# TODO.complete/77: Eliminate banned patterns from specs

## Status: done

The user's rules apply to specs too: no `double()`, no
`instance_double`, no `send` to private methods, no `respond_to?`.

## Sites eliminated

### `send(` to private methods (13 sites → 0)

| File | Private method | Fix |
|------|---------------|-----|
| `document_images_spec.rb` (4) | `Document#emit_images` | Already public — just call directly |
| `elements_package_contents_spec.rb` (5) | `Elements#package_content_lines_for` | `public :method` |
| `operation_renderer_spec.rb` (3) | `OperationRenderer.operation_text` | `public_class_method :method` |
| `label_box_parser_spec.rb` (1) | `DiagramBuilder#parse_label_boxes` | `public :method` |

Per user rule: "No `send` on private methods — promote tested methods
to public". All promoted.

### `double()` / `instance_double` (48 sites → 0)

| File | Doubles | Fix |
|------|---------|-----|
| `document_builder_spec.rb` | 24 | `Struct.new` fakes (FakePackage, FakeClass, FakeEnum, FakeAssociation) |
| `base_transformer_spec.rb` | 1 | `Ea::Qea::Database.new("test.qea")` |
| `attribute_transformer_spec.rb` | 1 | Same |
| `operation_transformer_spec.rb` | 2 | Same (removed unused Connection double) |
| `diagram_transformer_spec.rb` | 2 | Same |
| `generalization_transformer_spec.rb` | 2 | Same |
| `tagged_value_transformer_spec.rb` | 1 | `Ea::Qea::Database.new` |
| `constraint_transformer_spec.rb` | 1 | Same |
| `object_properties_spec.rb` | 1 | Same |
| `attribute_tags_spec.rb` | 1 | Same |
| `reference_resolver_spec.rb` | 2 | `Struct.new(:xmi_id, :name)` |
| `package_validator_spec.rb` | 1 | `Ea::Qea::Database.new` |
| `database_loader_spec.rb` | 1 | `TableDefinition.new(enabled: false)` |
| `package_contents_spec.rb` | 1 | `Struct.new(:attr_first_y)` |
| `instance_underline_spec.rb` | 1 | `Struct.new(:header_first_y)` |

### `respond_to?` in specs (2 sites → 0)

| File | Fix |
|------|-----|
| `comprehensive_equivalence_spec.rb:127` | `is_a?(Ea::Model::Classifier)` |
| `transformer_spec.rb:173` | Comment only (no code change needed) |

## Acceptance

- `grep -rn '[^a-z]double(' spec/` → 0 results
- `grep -rn 'instance_double' spec/` → 0 results
- `grep -rn '[^a-zA-Z]send(' spec/ | grep -v public_send` → 0 results
- `grep -rn 'respond_to?' spec/ | grep -v '^\s*#'` → 0 results
- Full suite: 2187 examples, 0 failures, 55 pending.
