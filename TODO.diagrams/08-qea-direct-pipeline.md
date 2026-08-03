# TODO-D 08-11 - QEA-direct pipeline

## Status: COMPLETE (2026-07-27)

## What was wired

1. **TODO-D 08**: QEA DiagramBuilder propagates StyleEx to
   Diagram.style_ex. Theme=:119 is now correctly detected from QEA.

2. **TODO-D 09**: IdNormalizer.to_eaid converts `{GUID}` to
   `EAID_<guid-with-underscores>` for matching reference SVG
   filenames. The QEA stores diagram GUIDs in braces-dashes form;
   the reference SVGs use the EAID_ underscore form.

3. **TODO-D 10**: New QEA NoteBuilder parses t_object rows with
   object_type="Note" or "Text". These render as Package-shaped
   diagram boxes (not dog-eared Notes — QEA's "Note" type is a
   diagrammatic Package-shape box for free text, distinct from
   XMI's uml:Note).

   Also: connector_type from t_connector.Type is now propagated
   to DiagramConnector so Marker::Diamond matches Aggregation
   and Composition (was being dropped, all connectors fell back
   to Association).

4. **TODO-D 11**: spec/ea/svg/qea_regression_spec.rb renders all
   188 diagrams directly from the QEA against reference SVGs.
   Passes at the 60 percent within-tolerance threshold.

## Parity delta from QEA-direct fixes

| Metric | Before | After |
|---|---|---|
| Polygon delta | n/a (was reading XMI) | -166 (was -842 at start) |
| Path delta | n/a | -181 |
| Text overlap avg | 10% (initial QEA-direct) | 56% |
| Within tolerance | 60.6% | 65.4% |

## Bonus fixes shipped alongside

- ClassifierBuilder no longer prepends package name to
  qualified_name (QEA t_object.Name already includes the prefix).
- HeaderLines no longer renders fallback stereotype labels.
- AttributeRenderer no longer double-colons type names.
- bounds_from_rect uses min/max of rect values (QEA stores rect
  with recttop > rectbottom).
