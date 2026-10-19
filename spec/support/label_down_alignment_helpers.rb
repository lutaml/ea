# frozen_string_literal: true

# Plateau diagrams 147 and 165: persisted alignment-zero source boxes leaving down.
module LabelDownAlignmentHelpers
  def down_alignment_records
    [{ role: "outerBuildingInstallation", anchor: [1073, 442], heading: [0, 126],
       box: { "ox" => 52, "oy" => -3, "alignment" => 0 }, style: { mode: "3", lwidth: "2" }, expected: [944, 454] },
     { role: "location", anchor: [912, 592], heading: [0, 88],
       box: { "ox" => 41, "oy" => 9, "alignment" => 0 }, style: { mode: "2", lwidth: "2" }, expected: [848, 616] }]
  end

  def down_alignment_controls
    [{ style: { mode: "3", lwidth: "2", stored_association_ray: true } },
     { style: { mode: "3", lwidth: "2", tree: "V" } },
     { style: { mode: "3", lwidth: "0" } }, { family: "Carlito" }, { stereotype: nil },
     { box: { "ox" => 0, "oy" => 0, "alignment" => 0 } }]
  end

  def down_alignment_positions(record, options = {})
    upward_property_positions(record, heading: record[:heading], **{ style: record[:style] }.merge(options))
  end

  def down_alignment_stored(record, options)
    box = options.fetch(:box, record[:box])
    [record[:anchor][0] + box["ox"], record[:anchor][1] - box["oy"]]
  end
end
