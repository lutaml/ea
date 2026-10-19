# frozen_string_literal: true

module D32HorizontalPropertyEndLabelHelpers
  def d32_horizontal_labels(stereotype: "property")
    render_association_ray_end(role: "relativeGMLGeometry", stereotype: stereotype,
                               source: [40, 710, 355, 90], target: [410, 720, 100, 80],
                               offsets: [25, 54], dimensions: [109, 31],
                               dock: "SX=-2;SY=-18;EX=-2;EY=-13;EDGE=2;")
  end
end
