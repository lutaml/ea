# 12 - Make from_db_row Data-Driven from YAML Schema

## Status: ✅ DONE

## What was verified
Zero custom `from_db_row` overrides in model files. All models use the
generic `BaseModel.from_db_row` with the `COLUMN_MAP` constant pattern:

```ruby
# BaseModel provides generic from_db_row
def self.from_db_row(row)
  # Uses COLUMN_MAP to map EA column names → Ruby attributes
end

# Each model only declares COLUMN_MAP
COLUMN_MAP = {
  "Object_ID" => :ea_object_id,
  "Name" => :name,
  # ...
}
```

Single source of truth: `config/qea_schema.yml` + `COLUMN_MAP` constants.
No duplication of column mappings.
