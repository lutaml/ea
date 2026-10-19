# frozen_string_literal: true

# Anchors and stored boxes of EA-published Plateau links (diagrams 34, 29, 146).
module LabelOrthogonalPropertyHelpers
  def orthogonal_property_records
    [
      { direction: :up, heading: [0, -66], role: "lod1MultiSurface", anchor: [663, 831],
        box: { "ox" => 63, "oy" => -80, "alignment" => 0 }, expected: [585, 745] },
      { direction: :left, heading: [-162, 0], role: "interior", anchor: [450, 268],
        box: { "ox" => 45, "oy" => -24, "alignment" => 0 }, expected: [396, 237] },
      { direction: :down, heading: [0, 39], role: "lod4MultiSurface", anchor: [949, 931],
        box: { "ox" => 275, "oy" => 39, "alignment" => 0 }, expected: [1078, 985] }
    ]
  end

  def orthogonal_property_controls
    [{ style: { mode: "1", lwidth: "2", tree: "OS" } }, { style: { mode: "3", lwidth: "0", tree: "OS" } },
     { family: "Carlito" }, { stereotype: nil }, { rotate: true }]
  end

  def orthogonal_property_positions(record, options = {})
    box = options[:rotate] ? record[:box].merge("rotation" => 90) : record[:box]
    style = { mode: "3", lwidth: "2", tree: "OS" }
    upward_property_positions(record, heading: record[:heading], box: box,
                                      **{ style: }.merge(options.except(:rotate)))
  end
end
