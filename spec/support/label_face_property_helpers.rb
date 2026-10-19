# frozen_string_literal: true

# Saved external rays of EA-published Plateau links (diagrams 91 and 65): the ray
# meets the source box through one face while the clipped leg runs elsewhere.
module LabelFacePropertyHelpers
  RAY_STYLE = { mode: "3", lwidth: "2", stored_association_ray: true, association_ray_outline: true }.freeze
  ABSENT_BOX = { "ox" => 0, "oy" => 0, "alignment" => 0 }.freeze

  def right_face_record
    { points: [[738, 696], [494, 582]], anchors: [[804, 707], [369, 649]], box: ABSENT_BOX,
      mult_box: ABSENT_BOX, source: [597, 650, 141, 70], target: [218, 544, 276, 224] }
  end

  def top_face_record
    { points: [[737, 262], [739, 681]], anchors: [[793, 190], [635, 577]], box: ABSENT_BOX,
      mult_box: ABSENT_BOX, source: [647, 262, 118, 80], target: [489, 457, 276, 224] }
  end

  def face_property_positions(record, style: RAY_STYLE)
    connector = build_heading_connector(record)
    connector.style = style
    heading_positions(connector, heading_bounds_for(record), role: "lod0Geometry", mult: "0..1")
  end
end
