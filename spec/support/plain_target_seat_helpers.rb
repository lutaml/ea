# frozen_string_literal: true

module PlainTargetSeatHelpers
  def plain_target_seat_options(style)
    { end_kind: :target, stereotype: nil, target_stereotype: nil, heading: [-133, 0], style: style }
  end

  def plain_target_seat_controls(box, style)
    route_controls = %i[plain_target_seat mode lwidth tree].zip([nil, "1", "0", "H"]).map do |key, value|
      { style: style.merge(key => value) }
    end
    route_controls + plain_target_box_controls(box) + plain_target_render_controls
  end

  def plain_target_box_controls(box)
    { "cy" => 35, "alignment" => 0, "bold" => true, "rotation" => 90, "color" => 255 }.map do |key, value|
      { box: box.merge(key => value) }
    end
  end

  def plain_target_render_controls
    [
      { type: "Aggregation" }, { target_stereotype: "Custom" },
      { family: "Arial" }, { size: 8 }, { unit: "px" },
      { heading: [-133, 1] }, { end_kind: :source, heading: [-133, 0] }
    ]
  end
end
