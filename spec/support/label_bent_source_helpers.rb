# frozen_string_literal: true

module LabelBentSourceHelpers
  # Plateau's published exterior/interior links omit LLT/LLB but store LRT/LRB.
  def bent_source_record(role)
    interior = role == "interior"
    { points: interior ? [[432, 406], [504, 383], [539, 365]] : [[432, 418], [508, 407], [539, 391]],
      anchors: [[432, 418], [539, 391]], box: { "ox" => 0, "oy" => 0, "alignment" => 0 },
      source: [331, 370, 100, 80], target: [540, 350, 100, 70] }
  end

  def bent_source_connector(record)
    connector = build_heading_connector(record)
    connector.label_boxes = connector.label_boxes.slice(:lrt)
    connector
  end
end
