# TODO.complete/80: Performance — ExtensionSerializer uses Database indexes

## Status: done

ExtensionSerializer was doing O(n) linear scans where the Database
already had O(1) indexes. On basic.qea (121 objects, 72 connectors)
this caused thousands of unnecessary comparisons per export; on larger
models it's a real bottleneck.

## Before (O(n) linear scans)

```ruby
source_obj = @database.collections[:objects]&.find { |o| o.ea_object_id == conn.start_object_id }
target_obj = @database.collections[:objects]&.find { |o| o.ea_object_id == conn.end_object_id }
obj = @database.collections[:objects]&.find { |o| o.ea_object_id == dl.instance_id }
parent = (@database.collections[:packages] || []).find { |p| p.package_id == pkg.parent_id }
pkg = (@database.collections[:packages] || []).find { |p| p.package_id == obj.package_id }
pkg = (@database.collections[:packages] || []).find { |p| p.package_id == dgm.package_id }
tagged.select { |tv| tv.element_id == element_guid }
```

## After (O(1) indexed lookups)

```ruby
source_obj = @database.find_object(conn.start_object_id)
target_obj = @database.find_object(conn.end_object_id)
obj = @database.find_object(dl.instance_id)
parent = @database.find_package(pkg.parent_id)
pkg = @database.find_package(obj.package_id)
pkg = @database.find_package(dgm.package_id)
@database.tagged_values_for_element(element_guid)
```

The Database already maintains `@objects_by_id`, `@packages_by_id`,
`@tagged_values_by_element_id` hash indexes — now they're used.

## Impact

- Export output is byte-identical (405898 bytes before and after).
- Lookup cost: O(connectors × objects) → O(connectors) for connector
  end resolution. For ArcGIS-scale models this is a 100x+ speedup.
- No new code: the Database methods already existed; ExtensionSerializer
  just wasn't calling them.
