# frozen_string_literal: true

module XmiNativeArcHelpers
  def native_svg_text(diagram_id)
    File.read(File.join(File.dirname(plateau_xmi_path), "Images", "#{diagram_id}.svg"))
  end

  def arc_end_seats(svg)
    svg.scan(/ A [\d.-]+ [\d.-]+ [\d.-]+ \d \d ([\d.-]+) ([\d.-]+)/).map { |x, y| [x.to_f.round, y.to_f.round] }.sort
  end

  def element_rects(svg)
    svg.scan(/<rect x="(\d+)" y="(\d+)" width="(\d+)" height="(\d+)" rx=/).map { |rect| rect.map(&:to_i) }
  end

  # Shift between two renderings, anchored on element rectangles whose
  # size is unique in both; every such anchor must give the same shift.
  def rect_anchor_shift(from_svg, to_svg)
    from = element_rects(from_svg)
    to = element_rects(to_svg)
    shifts = from.filter_map do |x, y, w, h|
      mates = to.select { |rect| rect.values_at(2, 3) == [w, h] }
      next unless mates.one? && from.count { |rect| rect.values_at(2, 3) == [w, h] } == 1

      [mates.first[0] - x, mates.first[1] - y]
    end
    shifts.uniq
  end
end
