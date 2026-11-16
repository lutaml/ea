# EA parity diagram exports

`manifest.yml` fixes the diagram set for the native EA SVG parity comparison.
The `model` path is relative to the repository root. Each entry records the
diagram's braced GUID, its export EAID, its exact name, and the cases it covers.
Use the GUID to distinguish diagrams with the same name.

## Coverage

The ten diagrams are Logical (class) diagrams spanning small and dense layouts,
stored connector edges, connector labels, and Note/Text objects. The counts in
`covers` come from the QEA's diagram placements and links, with connector edges
from `t_connector.Start_Edge` / `End_Edge`. Font coverage uses explicit
`font=Yu Gothic UI` settings in `t_diagramobjects.ObjectStyle` on every selected
diagram except CityGMLCore, which supplies a baseline without an explicit family.

`位置図_C0601` is the reproduction diagram named in
[#52](https://github.com/lutaml/ea/issues/52); the explicit fonts cover
[#53](https://github.com/lutaml/ea/issues/53).
No confirmed nil-coordinate reproduction for
[#51](https://github.com/lutaml/ea/issues/51) was identified in this model.
That issue uses `models/20260323_CityGML_3.0_Consolidated_Draft.qea`, a different
model. In the specified plateau model, no `t_diagramobjects.RectTop`, `RectLeft`,
`RectRight`, or `RectBottom` values, nor `t_connector.PtStartX`, `PtStartY`,
`PtEndX`, or `PtEndY` values, are SQL NULL. This does not prove that a rendering
path cannot produce nil; this set does not claim positive coverage of #51.

## Export from Enterprise Architect

1. Open `examples/qea/20251010_current_plateau_v5.1.qea` in Enterprise Architect.
2. Create `spec/fixtures/parity/reference/` in this checkout as the export target.
3. For each entry in `manifest.yml`, locate and open the diagram in EA's Browser.
   Check its diagram GUID against the entry's `guid`; do not select solely by name.
4. With that diagram active, choose **File > Save diagram as SVG**.
5. Save into `spec/fixtures/parity/reference/` using the entry's exact `eaid`
   followed by `.svg` (including the `EAID_` prefix and underscores).
6. Repeat for every entry. Keep the model's stored layout, fonts, labels, and
   connector positions unchanged. Export from EA with the model's fonts installed;
   do not substitute generated SVGs or hand-edit the reference exports.

The target for an entry is therefore
`spec/fixtures/parity/reference/<EAID>.svg`, relative to the repository root.
The reference SVGs are produced by the procedure above, not by the manifest spec.

## Validate the list

Run `bundle exec rspec spec/ea/svg/parity/manifest_spec.rb`.
This loads the QEA document and checks every GUID, name, and export EAID, as well
as duplicate GUIDs and missing coverage descriptions. It does not require the
native SVG exports and does not assert visual parity.
