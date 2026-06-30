# 08 - OCP: Connector Type Registry in StyleResolver

## Status: ✅ DONE

## What was verified
`StyleResolver` uses `CONNECTOR_TYPE_MAP` registry instead of `is_a?` chain:

```ruby
CONNECTOR_TYPE_MAP = {
  Lutaml::Uml::Generalization => "generalization",
  Lutaml::Uml::Association => "association",
  Lutaml::Uml::Dependency => "dependency",
  Lutaml::Uml::Realization => "realization",
}.freeze

def determine_connector_type(connector)
  return "association" unless connector

  type_name = CONNECTOR_TYPE_MAP[connector.class]
  return type_name if type_name && type_name != "association"
  return determine_association_type(connector) if type_name == "association"

  "association"
end
```

New connector types are added by registering in `CONNECTOR_TYPE_MAP`. OCP-compliant.
