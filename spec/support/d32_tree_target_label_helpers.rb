# frozen_string_literal: true

module D32TreeTargetLabelHelpers
  def d32_tree_target_labels(boxes: { "LRT" => [-26, -123], "LRB" => [-52, -31] })
    render_qea_end_labels(path: "460:-395;", boxes: boxes,
                          source: [100, 260, 250, 270], target: [410, 720, 100, 80],
                          end: :target, role: "lod4Geometry", mult: "0..1", stereotype: nil,
                          alignment: 1, style: "Mode=3;LWidth=0;TREE=LV;")
  end

  def d32_tree_target_positions(**options)
    record = { role: "lod4Geometry", mult: "0..1", anchor: [460, 720],
               box: { "ox" => -26, "oy" => -123, "alignment" => 1 } }
    upward_property_positions(record, end_kind: :target, stereotype: "", heading: [0, -325],
                                      style: { mode: "3", lwidth: "0", tree: "LV" },
                                      mult_box: { "ox" => -52, "oy" => -31, "alignment" => 1 }, **options)
  end
end
