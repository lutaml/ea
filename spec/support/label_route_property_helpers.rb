# frozen_string_literal: true

# Anchors and stored boxes of EA-published Plateau links (diagrams 163, 114, 73).
# Each record maps to one route class and carries the control that must not move.
module LabelRoutePropertyHelpers
  def route_property_records
    [route_property_mode_two, route_property_lateral, route_property_absent_box]
  end

  def route_property_mode_two
    { name: "mode 2 leftward", role: "lod1MultiSurface", anchor: [649, 270], heading: [-127, 0],
      box: { "ox" => 38, "oy" => -18, "alignment" => 0 }, style: { mode: "2", lwidth: "2" },
      expected: [546, 245], control: { style: { mode: "2", lwidth: "0" } } }
  end

  def route_property_lateral
    { name: "LH tree downward", role: "keyValuePairAttribute", anchor: [570, 381], heading: [0, 151],
      box: { "ox" => 43, "oy" => 3, "alignment" => 1 }, style: { mode: "3", lwidth: "2", tree: "LH" },
      expected: [446, 399], control: { style: { mode: "3", lwidth: "2", tree: "LV" } } }
  end

  def route_property_absent_box
    { name: "absent-box tree leftward", role: "lod0Network", anchor: [981, 698], heading: [-229, 0],
      box: { "ox" => 0, "oy" => 0, "alignment" => 0 }, style: { mode: "3", lwidth: "2" }, tree: true,
      expected: [858, 691], control: { style: { mode: "1", lwidth: "2" } } }
  end

  def route_property_positions(record, **overrides)
    options = { heading: record[:heading], style: record[:style], tree: record.fetch(:tree, false) }
    upward_property_positions(record, **options, **overrides)
  end

  # Where the label sits when the route rule does not apply.
  def route_property_stored(record)
    x, y = record[:anchor]
    return [x + 3, y - 23] if record[:tree]

    [x + record[:box]["ox"], y - record[:box]["oy"]]
  end
end
