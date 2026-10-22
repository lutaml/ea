# frozen_string_literal: true

# Shared render call for the 5038EEE3 reversed vertical-tree examples. Needs QeaRoutingHelpers; the including
# group defines the `multi_solid` and `plant_cover` boxes ([x, y, width, height]).
module QeaReversedTreeHelpers
  def render_reversed(geometry:, path:, source: multi_solid)
    render_qea_route(connector_type: "Association", source: source, target: plant_cover,
                     object_styles: ["DUID=MSMS;", "DUID=PCPC;"],
                     style: "Mode=3;EOID=MSMS;SOID=PCPC;Color=-1;LWidth=0;TREE=V;",
                     geometry: geometry, path: path)
  end
end
