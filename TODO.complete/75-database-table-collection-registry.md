# TODO.complete/75: Database table→collection registry (MECE)

## Status: done

`BaseValidator#get_collection_for_table` had a 22-branch case/when
mapping EA SQL table names to Database accessor methods. Adding a
new table required editing this method (OCP violation) and the
mapping was scattered (MECE violation — table knowledge lived in
the validator, not the database).

## After

`Ea::Qea::Database::TABLE_TO_COLLECTION` is the single source of
truth for the table_name → collection_name mapping. The new method
`Database#collection_for_table(name)` handles the special
ObjectRepository wrapping for `t_object`.

`BaseValidator#get_collection_for_table` now delegates:

```ruby
def get_collection_for_table(table)
  database.collection_for_table(table)
end
```

Adding a new table = adding one entry to `TABLE_TO_COLLECTION` in
`database.rb`. No validator code changes.

## Spec

`spec/ea/qea/database_spec.rb` — 4 new examples for
`#collection_for_table`.
