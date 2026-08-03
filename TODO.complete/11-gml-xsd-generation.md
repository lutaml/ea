# TODO.complete/11: GML XSD schema generation

## Status: done

The `GMLClassMapping.xml` file defines how UML classes map to GML XML
Schema constructs:

```xml
<Class name="FeatureType"
       element="featureMember"
       type="FeaturePropertyType"
       propertyType="..."/>
```

With this, we can generate GML XSD schemas from QEA models — a
high-value CLI feature that EA charges money for.

## Plan

1. Add `Ea::Export::Xsd::Generator` in `lib/ea/export/xsd/`.
2. Use the `GMLClassMapping` to translate:
   - Class with stereotype `FeatureType` → `<xs:element>` + `<xs:complexType>`.
   - Property with type `FeatureType` → property type reference.
   - Property of cardinality 0..n → `maxOccurs="unbounded"`.
3. Use `GMLNamespaces.xml` to declare target namespaces.
4. CLI: `ea export xsd model.qea --package core -o schema.xsd`.

## OCP / MECE

- Generator is a single class with a `call` method.
- Mapping rules loaded once from XML.
- Output is a Nokogiri::XML::Document, serialized to string.

## Acceptance

- Spec: generate XSD from test.qea TestSchema → matches expected root element.
- Spec: FeatureType class generates `<xs:element>` + complex type.
- Spec: property with targetNamespace picks up namespace from GMLNamespaces.

## Dependencies

- TODO.complete/10 (registry) for stereotype lookup.
