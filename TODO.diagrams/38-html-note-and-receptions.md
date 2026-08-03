# TODO-D 38: HTML note body rendering + receptions compartment

## Two related gaps

### HTML in note bodies

EA stores Note and Diagram Notes as RTF / HTML strings. When
rendered to SVG, EA strips the HTML tags and emits plain text
formatted to the visible character width.

We currently emit the raw HTML body verbatim — `<ul>`, `<li>`,
`<b>` tags appear as text in the SVG.

ArcGISWorkspace_template uses HTML notes heavily; this is the
biggest contributor to its 36.9% → ~55% text overlap gap.

### Receptions compartment

UML Class can declare "receptions" — `«signal» SignalName()`
entries that say the class accepts a Signal. EA renders these as
a 4th compartment below operations.

basic.qea "Basic Class Diagram with Receptions" misses
"receptions" header + 6 `«signal» Signal X()` entries.

## Acceptance (when picked up)

- HTML Note: strip tags using a simple HTML parser; wrap text at
  the note's pixel width; emit one `<text>` per wrapped line.
- Receptions: model as `Klass#receptions` collection of
  `Ea::Model::Reception {signal_ref, name}`; render in a
  dedicated compartment below operations.
