# frozen_string_literal: true

require "spec_helper"
require "ea"

# EA never draws an end-label role left of content x = 3. Each fixture is a
# verbatim slice of 20251010_current_plateau_v5.1.xmi whose saved UMLDI role
# bounds start left of that edge (x = -19, -6 and -1). The SVG x values are
# content x = 3 translated by each diagram's canvas inset; the native EA
# renders (EAID_<diagram>.svg) draw the roles at 8, 5 and 5 on their canvases.
RSpec.describe "End-label roles saved left of the canvas edge" do
  def texts_of(fixture)
    document = Ea::Sources::Xmi::Adapter.from_path(fixtures_path("issue135_route_style/#{fixture}"))
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document).render
    Nokogiri::XML(svg).xpath("//*[local-name()='text']")
            .to_h { |node| [node.text, [node["x"].to_f, node["y"].to_f]] }
  end

  {
    "47e4-left-edge-source-role.xmi" => ["+tunBaseAttribute", [33.0, 283.0], [49.0, 295.0]],
    "cb34-left-edge-source-role.xmi" => ["+bridBaseAttribute", [25.0, 295.0], [42.0, 307.0]],
    "159e-left-edge-target-role.xmi" => ["+startPoint", [-2.0, 186.0], [-2.0, 198.0]]
  }.each do |fixture, (role, role_pos, stereo_pos)|
    it "seats #{role} at the minimum role x with its stereotype moved alongside" do
      texts = texts_of(fixture)

      expect([texts[role], texts["«property»"]]).to eq([role_pos, stereo_pos])
    end
  end
end
