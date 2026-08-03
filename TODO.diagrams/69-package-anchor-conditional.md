# TODO-D 69: Package anchor marker conditional rendering

## Status: completed

The «import» connector's package_anchor marker (4-point closed
trapezoid at the source end) was rendered unconditionally,
causing 9 phantom paths on the plateau "Urban Planning ADE2"
diagram.

## Root cause

EA's t_diagramlinks.Geometry string carries explicit SX/SY/EX/EY
offset fields when the connector has been explicitly configured
with edge-attachment offsets. When SX/SY are absent, the
connector is auto-routed and EA suppresses the package_anchor
marker.

## Fix

Added `has_geometry_offsets` boolean to DiagramConnector model.
DiagramBuilder sets it by checking whether the raw Geometry
string contains "SX=". PackageImport marker returns [] when
false.

## Verification

- basic.qea Package Imports: SX=0;SY=0 present -> marker renders
- plateau Urban Planning ADE2: SX/SY absent -> no marker
- Urban Planning ADE2 delta dropped from 9 to 0 → matched
